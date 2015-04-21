using afIoc
using afMorphia

const mixin RepoPodFileDao : EntityDao {

	@Operator
	abstract RepoPodFile?	get(Str name, Bool checked := true)
	abstract RepoPodFile? 	find(Str name, Version version, Bool checked := true)

}

internal const class RepoPodFileDaoImpl : RepoPodFileDao {

	@Inject { type=RepoPodFile# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	new make(|This| in) { in(this) }
	
	override RepoPodFile? get(Str name, Bool checked := true) {
		datastore.query(field("_id").eq(name)).findOne(checked)
	}

	override RepoPodFile? find(Str name, Version version, Bool checked := true) {
		get(_id(name, version), false) 
	}
	
//	override Obj[] findAll() {
//		throw UnsupportedErr("No, I am NOT fetching ALL the pod files!")
//	}
	
	override RepoPodFile create(Obj entity) {
		return datastore.insert(entity)
	}

	
	private Str _id(Str name, Version version) {
		"${name.lower} ${version}"
	}
}
