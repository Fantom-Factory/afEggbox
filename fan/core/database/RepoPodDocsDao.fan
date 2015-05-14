using afIoc
using afMorphia

const mixin RepoPodDocsDao : EntityDao {

	@Operator
	abstract RepoPodDocs?	get(Str name, Bool checked := true)
	abstract RepoPodDocs? 	find(Str name, Version version, Bool checked := true)

}

internal const class RepoPodDocsDaoImpl : RepoPodDocsDao {

	@Inject { type=RepoPodDocs# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	new make(|This| in) { in(this) }
	
	override RepoPodDocs? get(Str name, Bool checked := true) {
		datastore.query(field("_id").eq(name)).findOne(checked)
	}

	override RepoPodDocs? find(Str name, Version version, Bool checked := true) {
		get(_id(name, version), checked) 
	}
	
	override RepoPodDocs create(Obj entity) {
		return datastore.insert(entity)
	}
	
	private Str _id(Str name, Version version) {
		"${name.lower}-${version}"
	}
}
