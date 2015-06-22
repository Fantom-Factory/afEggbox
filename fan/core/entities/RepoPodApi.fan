using afIoc
using afMorphia

@Entity { name = "podApi" }
class RepoPodApi {
	@Property	private const Str		_id
	@Property	private const Str		podName
	@Property	private const Str:Str	api
				private 	Str:DocType	docTypes	:= Str:DocType[:]
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Uri:Str contents) {
		newContents := Str:Str[:] { ordered = true }
		contents.keys.sort.each |uri| {
			if (!uri.isDir && uri.toStr.startsWith("/doc/") && uri.ext == "apidoc") {
				key := uri.relTo(`/doc/`).plusName(uri.name[0..<-7])

				// filter out unwanted docs
				docType := ApiDocParser(pod.name, contents[uri].in).parseType
				if (!docType.hasFacet("sys::NoDoc")     &&
					!DocFlags.isInternal(docType.flags) &&
					!DocFlags.isPrivate(docType.flags)  &&
					!DocFlags.isSynthetic(docType.flags))
					newContents[key.toStr] = contents[uri]
			}
		}

		return RepoPodApi {
			it._id		= pod._id
			it.podName	= pod.name
			it.api		= newContents
		}
	}

	Bool hasType(Str typeName) {
		api.containsKey(typeName)
	}

	@Operator
	DocType? get(Str typeName, Bool checked := true) {
		if (docTypes.containsKey(typeName))
			return docTypes[typeName]

		apidoc := api[typeName] ?: (checked ? throw Err("Pod api `$typeName` not found") : null)
		if (apidoc == null)
			return apidoc
		docType := ApiDocParser(podName, apidoc.toStr.in).parseType
		docTypes[typeName] = docType
		return docType
	}

	DocType[] allTypes() {
		docTypes.size == api.size ? docTypes.vals : api.keys.map { this.get(it) }
	}
	
	Str[] srcDocs() {
		allTypes.map { it.loc.file }.unique
	}
}
