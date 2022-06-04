using afMorphia::Entity
using afMorphia::BsonProp

@Entity { name = "podFile" }
class RepoPodFile {
	@BsonProp	Str		_id
	@BsonProp	Buf		data
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Buf podBuf) {
		RepoPodFile {
			it._id	= pod._id
			it.data	= podBuf.seek(0)
		}
	}
}
