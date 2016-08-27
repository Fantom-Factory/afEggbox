using afIoc
using afBson
using afMongo
using afMorphia

const mixin RepoPodDao : EntityDao {
	const static Func byProjName  := |RepoPod p1, RepoPod p2 -> Int| { p1.projectName.compareIgnoreCase(p2.projectName) }
	const static Func byBuildDate := |RepoPod p1, RepoPod p2 -> Int| { p1.builtOn.compare(p2.builtOn) }

	abstract RepoPod?		get(Str id, Bool checked := true)
	abstract RepoPod? 		findPod(Str name, Version? version := null)
	abstract RepoPod[]		findPodVersions(Str name, Int? limit := null)

	abstract RepoPod[]		findLatestPods(RepoUser? user := null)		// for All Pods page & sitemap
	abstract RepoPod[]		findOldestPods()							// for Index page
	abstract RepoPod[] 		findLatestVersions(Int limit)				// for main public atom feed	
	abstract Int			countPods(RepoUser? user := null)			// for All Pods and User page
	abstract Int			countVersions(RepoUser? user := null)		// for All Pods and User page

	** used for fanr queries
	abstract RepoPod[] 		doQuery(Str? podName, |Cursor->Obj?| f)

	abstract RepoPod 		toPod(Obj doc)	
}

internal const class RepoPodDaoImpl : RepoPodDao {

	@Inject { type=RepoPod# }
	override const Datastore datastore

	@Inject
	override const IntSequences	intSeqs

	@Inject	const DirtyCash 	dirtyCache
	@Inject	const UserSession	userSession
	
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
		       printjson(pods);
		       return asc ? pods.sort(sortByVersion)[pods.length-1] : pods.sort(sortByVersion)[0];
		   }"""
	
	new make(|This| in) { in(this) }
	
	override RepoPod? get(Str id, Bool checked := true) {
		// no cache as it's only used by testing
		datastore.query(allPods.field("_id").eq(id.lower)).findOne(checked)
	}

	override RepoPod? findPod(Str name, Version? version := null) {
		dirtyCache.get(RepoPod#, _id(name, version)) |->Obj?| {
			version != null
				? get(_id(name, version), false)
				: reduceByVersion(allPods.field("meta.pod\\u002ename").eqIgnoreCase(name), true).first
		}
	}

	override RepoPod[] findPodVersions(Str name, Int? limit := null) {
		query := allPods.field("meta.pod\\u002ename").eq(name)
		return datastore.query(query).orderByIndex("_builtOn_").limit(limit).findAll
	}
	
	override RepoPod[] findLatestPods(RepoUser? user := null) {
		query := user == null ? allPods : allPods.field("ownerId").eq(user._id)		
		return reduceByVersion(query, true).sort(byProjName)
	}

	override RepoPod[] findOldestPods() {
		return reduceByVersion(allPods, false).sort(byProjName)
	}
	
	override RepoPod[] findLatestVersions(Int limit) {
		// cheat by using 'builtOn' index and not the actual version
		return datastore.query(allPods).orderByIndex("_builtOn_").limit(limit).findAll
	}
	
	override Int countVersions(RepoUser? user := null) {
		query := user == null ? allPods : allPods.field("ownerId").eq(user._id)
		return datastore.query(allPods).findCount
	}

	override Int countPods(RepoUser? user := null) {
		query	 := user == null ? allPods : allPods.field("ownerId").eq(user._id)
		pipeline := [
			[
				"\$match" : query.toMongo(datastore)
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

		return datastore.collection.aggregate(pipeline).first?.get("count") ?: 0
	}

	override RepoPod[] doQuery(Str? podName, |Cursor->Obj?| f) {
		query := (Query) (podName == null ? allPods : allPods.field("meta.pod\\u002ename").eq(podName))
		return datastore.collection.find(query.toMongo(datastore), f)
	}
	
	override RepoPod toPod(Obj doc) {
		datastore.fromMongoDoc(doc)
	}

	override RepoPod create(Obj entity) {
		datastore.insert(entity)
	}
	
	// TODO: as map reduce is intended for background queries, should the repo get large, we may have to 
	// add an array of version Ints to the document and aggregate / group and sort on that.
	private RepoPod[] reduceByVersion(Query? query, Bool asc) {
		// need to ensure the collection exists else you get a "Mongo ns does not exist" Err
		// so just ensure the indexes and job done		
		mapFunc 	:= Code("function () { emit(this.meta['pod\\\\u002ename'], this); }")
		reduceFunc	:= Code(reduceByVersionFunc, ["asc":asc])
		options		:= [
			"query"	: query?.toMongo(datastore),
			"sort"	: ["_builtOn_" : 1]
		]
		if (query == null)
			options.remove("query")
		output 	:= datastore.collection.mapReduce(mapFunc, reduceFunc, options)
//		echo(Buf().writeObj(output, ["indent":0]).flip.readAllStr)
		vals 	:= (([Str:Obj?][]) output["results"]).map { it["value"] }
		pods	:= (RepoPod[]) vals .map { datastore.fromMongoDoc(it) }

		// dirty cash!
		if (asc)
			pods.each { 
				dirtyCache.put(RepoPod#, it._id, it)
				// I just happen to know this is the latest!
				dirtyCache.put(RepoPod#, "${it.name}-null", it)			
			}
//		echo("### $pods.size :: $pods")
		return pods
	}

	private Str _id(Str name, Version? version) {
		"${name}-${version}".lower
	}
	
	private Query allPods() {
		userSession.isLoggedIn
			? Query().or([
				field("meta.repo\\u002epublic").eq(true), 
				field("ownerId").eq(userSession.user._id)
			])
			: Query().field("meta.repo\\u002epublic").eq(true)
	}
}
