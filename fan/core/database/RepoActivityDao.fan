using afIoc
using afMorphia

const mixin RepoActivityDao : EntityDao {
	@Operator
	abstract RepoActivity?	get(Int id, Bool checked := true)
	abstract Void warn (Str msg, Err err)
	abstract Void error(Str msg, Err err)
}

internal const class RepoActivityDaoImpl : RepoActivityDao {

	@Inject { type=RepoActivity# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs
	
	@Inject	private const Log	log

	new make(|This| in) { in(this) }
	
	override RepoActivity? get(Int id, Bool checked := true) {
		datastore.query(field("_id").eq(id)).findOne(checked)
	}
	
	override Void warn(Str msg, Err err) {
		log.warn(msg, err)
		create(RepoActivity("warn", "${msg} :: ${err.typeof} - ${err.msg}"))
	}

	override Void error(Str msg, Err err) {
		log.err(msg, err)
		create(RepoActivity("error", "${msg} :: ${err.typeof} - ${err.msg}"))
	}
}
