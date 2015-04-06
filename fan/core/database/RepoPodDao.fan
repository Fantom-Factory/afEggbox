using afIoc
using afMorphia

const mixin RepoPodDao : EntityDao {

	@Operator
	abstract RepoPod?		get(Str name, Bool checked := true)
	abstract RepoPod[]		findAll()
}

internal const class RepoPodDaoImpl : RepoPodDao {

	@Inject { type=RepoPod# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	new make(|This| in) { in(this) }
	
	override RepoPod? get(Str name, Bool checked := true) {
		datastore.query(field("_id").eqIgnoreCase(name)).findOne(checked)
	}

	override RepoPod[] findAll() {
		datastore.query.orderBy("_id").findAll
	}
	
	override RepoPod create(Obj entity) {
		repoPod := (RepoPod) entity
		if (repoPod._id == null)
			repoPod._id = "${repoPod.name} ${repoPod.version}"
		return datastore.insert(repoPod)
	}
}
