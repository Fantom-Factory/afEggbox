using afIoc
using afMorphia

const mixin RepoActivityDao : EntityDao {
	@Operator
	abstract RepoActivity?	get(Int id, Bool checked := true)
	abstract Void warn (Str msg, Err err, Bool logErr)
	abstract Void error(Str msg, Err err, Bool logErr)
}

internal const class RepoActivityDaoImpl : RepoActivityDao {

	@Inject { type=RepoActivity# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs
	
	@Inject	private const Log			log
	@Inject	private const EggboxConfig	eggboxConfig

	new make(|This| in) { in(this) }
	
	override RepoActivity create(Obj entity) {
		eggboxConfig.logActivityEnabled
			? EntityDao.super.create(entity)
			: entity
	}
	
	override RepoActivity? get(Int id, Bool checked := true) {
		datastore.query(field("_id").eq(id)).findOne(checked)
	}
	
	override Void warn(Str msg, Err err, Bool logErr) {
		if (logErr) log.warn(msg, err)
		create(RepoActivity("warn", "${msg} :: ${err.typeof} - ${err.msg}"))
	}

	override Void error(Str msg, Err err, Bool logErr) {
		if (logErr) log.err(msg, err)
		create(RepoActivity("error", "${msg} :: ${err.typeof} - ${err.msg}"))
	}
}
