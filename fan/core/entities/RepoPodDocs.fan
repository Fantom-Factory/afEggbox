using afIoc
using afMorphia

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
	
	Str podDoc() {
		contents[`/doc/pod.fandoc`].readAllStr
	}
	
	@Operator
	Buf? get(Uri fileUri) {
		contents[fileUri]
	}
}
