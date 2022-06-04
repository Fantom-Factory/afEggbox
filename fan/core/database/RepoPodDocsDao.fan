using afIoc
using afMorphia

const abstract class RepoPodDocsDao : EntityDao {

	@Operator
	abstract RepoPodDocs?	get(Str _id, Bool checked := true)
	abstract RepoPodDocs? 	find(Str name, Version version, Bool checked := true)
	
	new make(|This| fn) : super(fn) { }
}

internal const class RepoPodDocsDaoImpl : RepoPodDocsDao {

	@Inject { type=RepoPodDocs# }
	override const Datastore datastore
	
	@Inject	const DirtyCash dirtyCache

	new make(|This| fn) : super(fn) { }

	override RepoPodDocs? get(Str id, Bool checked := true) {
		dirtyCache.get(RepoPodDocs#, id.lower) |->Obj?| {
			datastore.findOne(checked) { eq("_id", id) }
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
