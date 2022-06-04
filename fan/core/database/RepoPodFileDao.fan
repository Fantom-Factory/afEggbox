using afIoc
using afMorphia

const abstract class RepoPodFileDao : EntityDao {

	@Operator
	abstract RepoPodFile?	get(Str name, Bool checked := true)
	abstract RepoPodFile? 	find(Str name, Version version, Bool checked := true)
	
	new make(|This| fn) : super(fn) { }
}

internal const class RepoPodFileDaoImpl : RepoPodFileDao {

	@Inject { type=RepoPodFile# }
	override const Datastore datastore
	
	new make(|This| fn) : super(fn) { }
	
	override RepoPodFile? get(Str name, Bool checked := true) {
		datastore.findOne(checked) { eq("_id", name) }
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
		"${name.lower}-${version}"
	}
}
