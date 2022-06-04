using afMorphia::Entity
using afMorphia::BsonProp

@Entity { name = "podSrc" }
const class RepoPodSrc {
	@BsonProp private const Str		_id
	@BsonProp private const Str:Str	src
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Uri:Str contents, Str[] typeSrcFiles) {
		newContents := Str:Str[:] { ordered = true }
		contents.keys.sort.each |uri| {
			if (!uri.isDir && uri.toStr.startsWith("/src/")) {
				key := uri.relTo(`/src/`)
				if (typeSrcFiles.contains(key.toStr))
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
	
	Bool isEmpty() {
		src.isEmpty
	}
}
