using afIoc
using afMorphia

const mixin RepoPodDocsDao : EntityDao {

	@Operator
	abstract RepoPodDocs?	get(Str _id, Bool checked := true)
	abstract RepoPodDocs? 	find(Str name, Version version, Bool checked := true)

}

internal const class RepoPodDocsDaoImpl : RepoPodDocsDao {

	@Inject { type=RepoPodDocs# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	@Inject	const DirtyCash dirtyCache

	new make(|This| in) { in(this) }

	override RepoPodDocs? get(Str _id, Bool checked := true) {
		dirtyCache.get(RepoPodDocs#, _id.lower) |->Obj?| {
			datastore.query(field("_id").eq(_id)).findOne(checked)
		}
	}

	override RepoPodDocs? find(Str name, Version version, Bool checked := true) {
		dirtyCache.get(RepoPodDocs#, _id(name, version)) |->Obj?| {
			get(_id(name, version), checked)
		}
	}
	
	override RepoPodDocs create(Obj entity) {
		return datastore.insert(entity)
	}
	
	private Str _id(Str name, Version version) {
		"${name.lower}-${version}"
	}
}
