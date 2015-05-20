using afIoc
using afMorphia

@Entity { name = "podSrc" }
class RepoPodSrc {
	@Property {}	Str		_id
	@Property {}	Uri:Str	contents
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Uri:Str contents) {
		RepoPodSrc {
			it._id		= pod._id
			it.contents	= contents
		}
	}
	
	@Operator
	Str? get(Str fileName) {
		contents[`/src/${fileName}`]
	}
}
