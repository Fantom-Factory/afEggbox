using afIoc
using afMorphia

const mixin RepoPodDao : EntityDao {

	@Operator
	abstract RepoPod?		get(Str name, Bool checked := true)
	abstract RepoPod[]		findAll()
	abstract RepoPod 		find(Str name, Version? version, Bool checked := true)
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
	
	override RepoPod find(Str name, Version? version, Bool checked := true) {
		if (version != null)
			return get(_id(name, version))
	
//    // if version null, then find latest one
//    if (ver == null) return dir.cur

		throw UnknownPodErr()
		
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
