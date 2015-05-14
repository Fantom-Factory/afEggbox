using afIoc
using afMorphia

const mixin RepoPodSrcDao : EntityDao {

	@Operator
	abstract RepoPodSrc?	get(Str name, Bool checked := true)
	abstract RepoPodSrc? 	find(Str name, Version version, Bool checked := true)

}

internal const class RepoPodSrcDaoImpl : RepoPodSrcDao {

	@Inject { type=RepoPodSrc# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	new make(|This| in) { in(this) }
	
	override RepoPodSrc? get(Str name, Bool checked := true) {
		datastore.query(field("_id").eq(name)).findOne(checked)
	}

	override RepoPodSrc? find(Str name, Version version, Bool checked := true) {
		get(_id(name, version), checked) 
	}
	
	override RepoPodSrc create(Obj entity) {
		return datastore.insert(entity)
	}
	
	private Str _id(Str name, Version version) {
		"${name.lower}-${version}"
	}
}
