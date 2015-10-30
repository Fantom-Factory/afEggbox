using afIoc
using afMorphia

@Entity { name = "podFile" }
class RepoPodFile {
	@Property	Str		_id
	@Property	Buf		data
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Buf podBuf) {
		RepoPodFile {
			it._id	= pod._id
			it.data	= podBuf.seek(0)
		}
	}
}
