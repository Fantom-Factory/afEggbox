using afIoc
using afMorphia

const mixin RepoPodSrcDao : EntityDao {

	@Operator
	abstract RepoPodSrc?	get(Str _id, Bool checked := true)
	abstract RepoPodSrc? 	find(Str name, Version version, Bool checked := true)

}

internal const class RepoPodSrcDaoImpl : RepoPodSrcDao {

	@Inject { type=RepoPodSrc# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	@Inject	const DirtyCash dirtyCache

	new make(|This| in) { in(this) }
	
	override RepoPodSrc? get(Str _id, Bool checked := true) {
		dirtyCache.get(RepoPodSrc#, _id.lower) |->Obj?| {
			datastore.query(field("_id").eq(_id)).findOne(checked)
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
