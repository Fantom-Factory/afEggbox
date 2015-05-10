using afIoc
using afBson
using afMongo
using afMorphia

const mixin RepoPodDao : EntityDao {

	@Operator
	abstract RepoPod?		get(Str name, Bool checked := true)
	abstract RepoPod[]		findAll()
	abstract RepoPod? 		findOne(Str name, Version? version := null)

	abstract RepoPod[] 		findPublic(RepoUser? loggedInUser)
	abstract RepoPod[] 		findPrivate(RepoUser loggedInUser)

	** used for fanr queries
	abstract RepoPod[] 		query(|Cursor->Obj?| f)

	abstract RepoPod toPod(Obj doc)
}

internal const class RepoPodDaoImpl : RepoPodDao {

	@Inject { type=RepoPod# }
	override const Datastore datastore

	@Inject
	override const IntSequences	intSeqs

	private const Str	reduceFunc	:= 
		"""function (key, pods) { 
		       function sortByVersion(a, b) {
		           var i, cmp, len, re = /(\\.0)+[^\\.]*\$/;
		           a = (a + '').replace(re, '').split('.');
		           b = (b + '').replace(re, '').split('.');
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
		datastore.query(field("_id").eq(_id.lower)).findOne(checked)
	}

	override RepoPod[] findAll() {
		datastore.query.orderBy("_id").findAll
	}
	
	override RepoPod? findOne(Str name, Version? version := null) {
		if (version != null)
			return get(_id(name, version), false)
	
		return datastore.query(field("name").eqIgnoreCase(name))
			.findAll
			.sort |RepoPod p1, RepoPod p2->Int| { p2.version <=> p1.version }
			.first 
	}

	override RepoPod[] findPublic(RepoUser? user) {
		// see http://stackoverflow.com/questions/7717109/how-can-i-compare-arbitrary-version-numbers/7717160#7717160
		mapFunc 	:= Code("function () { emit(this.name, this); }")
		reduceFunc	:= Code(this.reduceFunc)
		
		query		:= Query().field("isPublic").eq(true)
		if (user != null)
			query	= Query().or([query, field("ownerId").eq(user._id)])

		output 		:= datastore.collection.mapReduce(mapFunc, reduceFunc, [
			"query" : query.toMongo(datastore),
			"sort" : ["_name_" : 1]
		])
		
		pods := (([Str:Obj?][]) output["results"]).map { it["value"] }
		return pods.map { datastore.fromMongoDoc(it) }
	}
	
	override RepoPod[] findPrivate(RepoUser user) {
		// see http://stackoverflow.com/questions/7717109/how-can-i-compare-arbitrary-version-numbers/7717160#7717160
		mapFunc 	:= Code("function () { emit(this.name, this); }")
		reduceFunc	:= Code(this.reduceFunc)
		output 		:= datastore.collection.mapReduce(mapFunc, reduceFunc, [
			"query"	: Query().field("ownerId").eq(user._id).toMongo(datastore),
			"sort"	: ["_name_" : 1]
		])
		
		pods := (([Str:Obj?][]) output["results"]).map { it["value"] }
		return pods.map { datastore.fromMongoDoc(it) }
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
	
	private Str _id(Str name, Version version) {
		"${name.lower} ${version}"
	}
}
