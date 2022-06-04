using afIoc
using afMorphia

const abstract class RepoPodSrcDao : EntityDao {

	@Operator
	abstract RepoPodSrc?	get(Str _id, Bool checked := true)
	abstract RepoPodSrc? 	find(Str name, Version version, Bool checked := true)

	new make(|This| fn) : super(fn) { }
}

internal const class RepoPodSrcDaoImpl : RepoPodSrcDao {

	@Inject { type=RepoPodSrc# }
	override const Datastore datastore
	
	@Inject	const DirtyCash dirtyCache

	new make(|This| fn) : super(fn) { }
	
	override RepoPodSrc? get(Str id, Bool checked := true) {
		dirtyCache.get(RepoPodSrc#, id.lower) |->Obj?| {
			datastore.findOne(checked) { eq("_id", id) }
		}
	}

	override RepoPodSrc? find(Str name, Version version, Bool checked := true) {
		dirtyCache.get(RepoPodSrc#, _id(name, version)) |->Obj?| {
			get(_id(name, version), checked)
		}
	}
	
	override RepoPodSrc create(Obj entity) {
		return datastore.insert(entity)
	}
	
	private Str _id(Str name, Version version) {
		"${name}-${version}".lower
	}
}
