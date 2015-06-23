using afIoc
using afMorphia

const mixin RepoPodDownloadDao : EntityDao {
	@Operator
	abstract RepoPodDownload?	get(Int id, Bool checked := true)
}

internal const class RepoPodDownloadDaoImpl : RepoPodDownloadDao {

	@Inject { type=RepoPodDownload# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	@Inject	private const EggboxConfig	eggboxConfig

	new make(|This| in) { in(this) }
	
	override RepoPodDownload create(Obj entity) {
		eggboxConfig.logDownloadsEnabled
			? EntityDao.super.create(entity)
			: entity
	}

	override RepoPodDownload? get(Int id, Bool checked := true) {
		datastore.query(field("_id").eq(id)).findOne(checked)
	}
}
