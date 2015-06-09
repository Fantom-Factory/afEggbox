using afIoc
using afBson
using afMongo
using afMorphia

const mixin RepoPodDao : EntityDao {

	@Operator
	abstract RepoPod?		get(Str name, Bool checked := true)
	abstract RepoPod[]		findAll()
	abstract RepoPod[]		findVersions(RepoUser? user, Str name, Int? limit)
	abstract RepoPod? 		findOne(Str name, Version? version := null)

	abstract RepoPod[] 		findPublic(RepoUser? loggedInUser)			// for All Pods page & sitemap
	abstract Int	 		countPublicVersions(RepoUser? user)			// for All Pods and User page
	abstract Int	 		countPublicPods(RepoUser? user)				// for All Pods and User page

	abstract RepoPod[] 		findPublicVersions(Int limit)				// for main public atom feed
	abstract RepoPod[] 		findPrivateOwned(RepoUser loggedInUser)		// for My Pods page
	abstract RepoPod[] 		findPublicOwned(RepoUser loggedInUser)		// for Users page

	** used for fanr queries
	abstract RepoPod[] 		query(|Cursor->Obj?| f)

	abstract RepoPod 		toPod(Obj doc)	
}

internal const class RepoPodDaoImpl : RepoPodDao {

	@Inject { type=RepoPod# }
	override const Datastore datastore

	@Inject
	override const IntSequences	intSeqs

	@Inject	const DirtyCash dirtyCache

	// see http://stackoverflow.com/questions/7717109/how-can-i-compare-arbitrary-version-numbers/7717160#7717160
	private const Str	reduceByVersionFunc	:= 
		"""function (key, pods) { 
		       function sortByVersion(podA, podB) {
		           var i, cmp, len, re = /(\\.0)+[^\\.]*\$/;
		           var a = (podA.meta['pod\\\\u002eversion'] + '').replace(re, '').split('.');
		           var b = (podB.meta['pod\\\\u002eversion'] + '').replace(re, '').split('.');
		           len = Math.min(a.length, b.length);
		           for (i = 0; i < len; i++) {
		               cmp = parseInt(a[i], 10) - parseInt(b[i], 10);
		               if (cmp !== 0) {
		                   return cmp;
		               }
		           }
		           return a.length - b.length;
		       };
		   
		       return pods.sort(sortByVersion)[pods.length-1];
		   }"""
	
	new make(|This| in) { in(this) }
	
	override RepoPod? get(Str _id, Bool checked := true) {
		dirtyCache.get(RepoPod#, _id.lower) |->Obj?| {
			datastore.query(field("_id").eq(_id.lower)).findOne(checked)
		}
	}

	override RepoPod[] findAll() {
		datastore.query.orderBy("_id").findAll
	}
	
	override RepoPod[] findVersions(RepoUser? user, Str name, Int? limit) {
		query := field("meta.pod\\u002ename").eq(name)
		if (user == null)
			query.field("meta.repo\\u002epublic").eq(true)
		else
			query.or([field("meta.repo\\u002epublic").eq(true), field("ownerId").eq(user._id)])
		return datastore.query(query).orderByIndex("_builtOn_").limit(limit).findAll
	}
	
	override RepoPod? findOne(Str name, Version? version := null) {
		dirtyCache.get(RepoPod#, _id(name, version)) |->Obj?| {
			version != null
				? get(_id(name, version), false)
				: reduceByVersion(field("meta.pod\\u002ename").eqIgnoreCase(name)).first
		}
	}

	override RepoPod[] findPublic(RepoUser? user) {
		query := Query().field("meta.repo\\u002epublic").eq(true)
		
		// if pod is deprecated, we need to remove the entire project, not just individual versions
		//.field("meta.repo\\u002edeprecated").notEq(true)
		if (user != null)
			query = Query().or([query, field("ownerId").eq(user._id)])
		return reduceByVersion(query)
	}
	
	override RepoPod[] findPublicVersions(Int limit) {
		query := Query().field("meta.repo\\u002epublic").eq(true)
		return datastore.query(query).orderByIndex("_builtOn_").limit(limit).findAll
	}
	
	override RepoPod[] findPrivateOwned(RepoUser user) {
		user.isAdmin ? reduceByVersion(null) : reduceByVersion(field("ownerId").eq(user._id))
	}
	
	override RepoPod[] findPublicOwned(RepoUser user) {
		reduceByVersion(field("ownerId").eq(user._id).field("meta.repo\\u002epublic").eq(true))
	}
	
	override Int countPublicVersions(RepoUser? user) {
		query := Query().field("meta.repo\\u002epublic").eq(true)
		if (user != null)
			query = Query().and([query, field("ownerId").eq(user._id)])
		return datastore.query(query).findCount		
	}

	override Int countPublicPods(RepoUser? user) {
		pipeline := [
			[
				"\$match" : [
					"meta.repo\\u002epublic" 	: true,
					"ownerId"					: user?._id
				]
			],
			[
				"\$group" : [
					"_id" : "\$meta.pod\\u002ename"
				] 
			],
			[
				"\$group" : [
					"_id": 1, 
					"count": [
						"\$sum" : 1
					]
				]
			]
		]

		if (user == null)
			pipeline[0]["\$match"] = ["meta.repo\\u002epublic" : true]

		return datastore.collection.aggregate(pipeline).first?.get("count") ?: 0
	}

	override RepoPod[] query(|Cursor->Obj?| f) {
		datastore.collection.find([:], f)
	}
	
	override RepoPod toPod(Obj doc) {
		datastore.fromMongoDoc(doc)
	}

	override RepoPod create(Obj entity) {
		repoPod := (RepoPod) entity
		if (repoPod._id == null)
			repoPod._id = _id(repoPod.name, repoPod.version)
		return datastore.insert(repoPod)
	}
	
	// TODO: as map reduce is intended for background queries, should the repo get large, we may have to 
	// add an array of version Ints to the document and aggregate / group and sort on that.
	private RepoPod[] reduceByVersion(Query? query) {
		// need to ensure the collection exists else you get a "Mongo ns does not exist" Err
		// so just ensure the indexes and job done		
		mapFunc 	:= Code("function () { emit(this.meta['pod\\\\u002ename'], this); }")
		reduceFunc	:= Code(reduceByVersionFunc)
		options		:= [
			"query"	: query?.toMongo(datastore),
			"sort"	: ["_podName_" : 1]
		]
		if (query == null)
			options.remove("query")
		output 	:= datastore.collection.mapReduce(mapFunc, reduceFunc, options)
		pods 	:= (([Str:Obj?][]) output["results"]).map { it["value"] }
		return pods.map { datastore.fromMongoDoc(it) }.sort |RepoPod p1, RepoPod p2 -> Int| { p1.projectName.compareIgnoreCase(p2.projectName) }
	}

	private Str _id(Str name, Version? version) {
		"${name}-${version}".lower
	}
}
