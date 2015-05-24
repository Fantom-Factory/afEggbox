using afIoc
using afMorphia

@Entity { name = "podApi" }
class RepoPodApi {
	@Property	const Str			_id
	@Property	const Str			podName
	@Property	const Uri:Str		contents
					  Str:DocType	docTypes	:= Str:DocType[:]
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Uri:Str contents) {
		RepoPodApi {
			it._id		= pod._id
			it.podName	= pod.name
			it.contents	= contents
		}
	}
	
	@Operator
	DocType? get(Str typeName, Bool checked := true) {
		if (docTypes.containsKey(typeName))
			return docTypes[typeName]
		
		apidoc := contents[`/doc/${typeName}.apidoc`] ?: (checked ? throw Err("Pod api `$typeName` not found") : null)
		if (apidoc == null)
			return apidoc
		docType := ApiDocParser(podName, apidoc.toStr.in).parseType
		docTypes[typeName] = docType
		return docType
	}
	
	DocType[] allTypes() {
		contents.keys.sort.map { this.get(it.name[0..<it.name.indexr(".")]) }
	}
}
