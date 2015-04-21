using afIoc
using afMongo
using afMorphia

const mixin RepoPodDao : EntityDao {

	@Operator
	abstract RepoPod?		get(Str name, Bool checked := true)
	abstract RepoPod[]		findAll()
	abstract RepoPod? 		find(Str name, Version? version)

	abstract RepoPod[] 		query(|Cursor->Obj?| f)

	abstract RepoPod toPod(Obj doc)
}

internal const class RepoPodDaoImpl : RepoPodDao {

	@Inject { type=RepoPod# }
	override const Datastore datastore

	@Inject
	override const IntSequences	intSeqs

	new make(|This| in) { in(this) }
	
	override RepoPod? get(Str _id, Bool checked := true) {
		datastore.query(field("_id").eqIgnoreCase(_id)).findOne(checked)
	}

	override RepoPod[] findAll() {
		datastore.query.orderBy("_id").findAll
	}
	
	override RepoPod? find(Str name, Version? version) {
		if (version != null)
			return get(_id(name, version), false)
	
		return datastore.query(field("name").eqIgnoreCase(name))
			.findAll
			.sort |RepoPod p1, RepoPod p2->Int| { p2.version <=> p1.version }
			.first 
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
