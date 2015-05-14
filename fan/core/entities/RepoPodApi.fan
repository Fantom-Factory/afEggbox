using afIoc
using afMorphia

@Entity { name = "podApi" }
class RepoPodApi {
	@Property {}	Str		_id
	@Property {}	Uri:Str	contents
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Uri:Str contents) {
		RepoPodApi {
			it._id		= pod._id
			it.contents	= contents
		}
	}
	
	@Operator
	Str? get(Uri fileUri) {
		contents[fileUri]
	}
}
