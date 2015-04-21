using afIoc
using afMorphia

@Entity { name = "podFile" }
class RepoPodFile {
	@Property	Str		_id
	@Property	Buf		data
	
	@Inject	// TODO: delete this!
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, File file) {
		RepoPodFile {
			it._id	= pod._id
			it.data	= file.readAllBuf
		}
	}
}
