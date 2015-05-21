using afIoc
using afMorphia
using fandoc

@Entity { name = "podDocs" }
class RepoPodDocs {
	@Property {}	Str		_id
	@Property {}	Uri:Buf	contents
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Uri:Buf contents) {
		RepoPodDocs {
			it._id		= pod._id
			it.contents	= contents
		}
	}
	
	@Operator
	Buf? get(Uri fileUri, Bool checked := true) {
		contents[fileUri]?.seek(0) ?: (checked ? throw Err("Pod doc `$fileUri` not found") : null)
	}
}
