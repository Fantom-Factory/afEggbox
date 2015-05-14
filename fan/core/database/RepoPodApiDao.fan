using afIoc
using afMorphia

const mixin RepoPodApiDao : EntityDao {

	@Operator
	abstract RepoPodApi?	get(Str name, Bool checked := true)
	abstract RepoPodApi? 	find(Str name, Version version, Bool checked := true)

}

internal const class RepoPodApiDaoImpl : RepoPodApiDao {

	@Inject { type=RepoPodApi# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	new make(|This| in) { in(this) }
	
	override RepoPodApi? get(Str name, Bool checked := true) {
		datastore.query(field("_id").eq(name)).findOne(checked)
	}

	override RepoPodApi? find(Str name, Version version, Bool checked := true) {
		get(_id(name, version), checked) 
	}
	
	override RepoPodApi create(Obj entity) {
		return datastore.insert(entity)
	}
	
	private Str _id(Str name, Version version) {
		"${name.lower}-${version}"
	}
}
