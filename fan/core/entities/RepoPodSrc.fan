using afIoc
using afMorphia

@Entity { name = "podSrc" }
const class RepoPodSrc {
	@Property const Str		_id
	@Property const Uri:Str	contents
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Uri:Str contents) {
		RepoPodSrc {
			it._id		= pod._id
			it.contents	= contents
		}
	}
	
	@Operator
	Str? get(Str fileName, Bool checked := true) {
		contents[`/src/${fileName}`] ?: (checked ? throw Err("Pod src `$fileName` not found") : null)
	}
}
