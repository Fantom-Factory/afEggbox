using afIoc
using afMorphia

const abstract class RepoPodDownloadDao : EntityDao {
	@Operator
	abstract RepoPodDownload?	get(Int id, Bool checked := true)
	
	new make(|This| fn) : super(fn) { }
}

internal const class RepoPodDownloadDaoImpl : RepoPodDownloadDao {

	@Inject { type=RepoPodDownload# }
	override const Datastore datastore
	
	@Inject	private const EggboxConfig	eggboxConfig

	new make(|This| fn) : super(fn) { }
	
	override RepoPodDownload create(Obj entity) {
		eggboxConfig.logDownloadsEnabled
			? super.create(entity)
			: entity
	}

	override RepoPodDownload? get(Int id, Bool checked := true) {
		datastore.findOne(checked) { eq("_id", id) }
	}
}
