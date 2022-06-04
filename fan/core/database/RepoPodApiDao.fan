using afIoc::Inject
using afMorphia::Datastore

const abstract class RepoPodApiDao : EntityDao {

	@Operator
	abstract RepoPodApi?	get(Str _id, Bool checked := true)
	abstract RepoPodApi? 	find(Str name, Version version, Bool checked := true)
	
	new make(|This| fn) : super(fn) { }
}

internal const class RepoPodApiDaoImpl : RepoPodApiDao {

	@Inject { type=RepoPodApi# }
	override const Datastore datastore
	
	@Inject	const DirtyCash dirtyCache

	new make(|This| fn) : super(fn) { }
	
	override RepoPodApi? get(Str id, Bool checked := true) {
		dirtyCache.get(RepoPodApi#, id.lower) |->Obj?| {
			datastore.findOne(checked) { eq("_id", id) }
		}
	}

	override RepoPodApi? find(Str name, Version version, Bool checked := true) {
		dirtyCache.get(RepoPodApi#, _id(name, version)) |->Obj?| {
			get(_id(name, version), checked)
		}
	}
	
	override RepoPodApi create(Obj entity) {
		return datastore.insert(entity)
	}
	
	private Str _id(Str name, Version version) {
		"${name}-${version}".lower
	}
}
