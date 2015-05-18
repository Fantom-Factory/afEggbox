using afIoc
using afMorphia

const mixin RepoPodApiDao : EntityDao {

	@Operator
	abstract RepoPodApi?	get(Str _id, Bool checked := true)
	abstract RepoPodApi? 	find(Str name, Version version, Bool checked := true)

}

internal const class RepoPodApiDaoImpl : RepoPodApiDao {

	@Inject { type=RepoPodApi# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	@Inject	const DirtyCash dirtyCache

	new make(|This| in) { in(this) }
	
	override RepoPodApi? get(Str _id, Bool checked := true) {
		dirtyCache.get(RepoPodApi#, _id.lower) |->Obj?| {
			datastore.query(field("_id").eq(_id)).findOne(checked)
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
