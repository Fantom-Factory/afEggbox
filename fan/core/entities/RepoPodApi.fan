using afIoc
using afMorphia

@Entity { name = "podApi" }
class RepoPodApi {
	@Property {}	Str		_id
	@Property {}	Str?	podName	// FIXME: make not-nullable (once we delete existing data)
	@Property {}	Uri:Str	contents
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Uri:Str contents) {
		RepoPodApi {
			it._id		= pod._id
			it.podName	= pod.name
			it.contents	= contents
		}
	}
	
	@Operator
	Str? get(Uri fileUri) {
		contents[fileUri]
	}
	
	DocType[] mixins() {
		allTypes.findAll { it.isMixin }
	}
	
	DocType[] classes() {
		allTypes.findAll { !it.isMixin && !it.isFacet && !it.isEnum && !it.isErr}
	}
	
	DocType[] enums() {
		allTypes.findAll { it.isEnum }
	}
	
	DocType[] facets() {
		allTypes.findAll { it.isFacet }
	}
	
	DocType[] errs() {
		allTypes.findAll { it.isErr }
	}
	
	once DocType[] allTypes() {
		contents.vals
			.map { ApiDocParser(podName ?: _id.split('-').first, it.in).parseType }
			.exclude |DocType t->Bool| {
				t.hasFacet("sys::NoDoc")     ||
				DocFlags.isInternal(t.flags) ||
				DocFlags.isPrivate(t.flags)  ||
				DocFlags.isSynthetic(t.flags)
			} 
	}
}
