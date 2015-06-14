using afIoc
using afMorphia

@Entity { name = "podSrc" }
const class RepoPodSrc {
	@Property private const Str		_id
	@Property private const Str:Str	src
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Uri:Str contents) {
		newContents := Str:Str[:] { ordered = true }
		contents.keys.sort.each |uri| {
			if (!uri.isDir && uri.toStr.startsWith("/src/")) {
				key := uri.relTo(`/src/`)
				newContents[key.toStr] = contents[uri]
			}
		}
		
		return RepoPodSrc {
			it._id	= pod._id
			it.src	= newContents
		}
	}
	
	@Operator
	Str? get(Str fileName, Bool checked := true) {
		src[fileName] ?: (checked ? throw Err("Pod src `$fileName` not found") : null)
	}
}
