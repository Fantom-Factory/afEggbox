using afIoc::Inject
using afMorphia::Datastore
using afMongo::MongoSeqs

const abstract class RepoActivityDao : EntityDao {
	@Operator
	abstract RepoActivity?	get(Int id, Bool checked := true)
	abstract Void warn (Str msg, Err err, Bool logErr)
	abstract Void error(Str msg, Err err, Bool logErr)
	
	new make(|This| fn) : super(fn) { }
}

internal const class RepoActivityDaoImpl : RepoActivityDao {

	@Inject { type=RepoActivity# }
	override 		const Datastore		datastore
	@Inject	private const Log			log
	@Inject	private const EggboxConfig	eggboxConfig

	new make(|This| fn) : super(fn) { }
	
	override RepoActivity create(Obj entity) {
		eggboxConfig.logActivityEnabled
			? super.create(entity)
			: entity
	}
	
	override RepoActivity? get(Int id, Bool checked := true) {
		datastore.findOne(checked) { eq("_id", id) }
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
