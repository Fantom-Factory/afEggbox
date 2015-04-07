using afMorphia
using fandoc

@Entity { name = "pod" }
class RepoPod {
	@Property	Str?		_id
	@Property	Str			name
	@Property	Version		version
	@Property	Int			fileSize
	@Property	Bool		isPublic
	@Property	Str			ownerId
	@Property	Str			aboutFandoc
	@Property	RepoPodMeta	meta

	new make(|This|f) { f(this) }
	
	static new fromFile(File podFile, RepoUser user) {
		zip	:= Zip.open(podFile)
		try {
			meta 	:= zip.contents[`/meta.props`].readProps

			return RepoPod() {
				it.name			= meta["pod.name"]
				it.fileSize		= podFile.size
				it.version		= Version(meta["pod.version"])
				it.meta			= RepoPodMeta(zip.contents[`/meta.props`].readProps)
				it.aboutFandoc	= findAboutFandoc(zip)
				it.isPublic		= false	// FIXME: isPublic
				it.ownerId		= user.userName
			}

		} finally {
			zip.close
		}
	}
	
	private Str findAboutFandoc(Zip zip) {
		aboutFd := zip.contents[`/doc/about.fdoc`]?.readAllStr		
		if (aboutFd != null)
			return aboutFd
		
		if (zip.contents[`/doc/pod.fandoc`] != null) {
			podFd := zip.contents[`/doc/pod.fandoc`].readAllStr
			
			overview := (Heading?) null
			foundOverview := false
			elems := DocElem[,]
			FandocParser().parseStr(podFd).children.find |kid->Bool| {
				if (foundOverview) {
					if ((kid.id == DocNodeId.heading) && ((Heading) kid).level == overview.level)
						return true
					elems.add(kid)
					return false
				}
				foundOverview = (kid.id == DocNodeId.heading) && ((Heading) kid).title.trim.equalsIgnoreCase("Overview")
				if (foundOverview)
					overview = kid
				return false
			}
			
			if (!elems.isEmpty) {
				buff	:= StrBuf()
				fanw	:= FandocDocWriter(buff.out)
				elems.each { it.write(fanw) }
				return buff.toStr				
			}
		}
		
		meta := zip.contents[`/meta.props`].readProps
		return meta["summary"] ?: (meta["podName"] ?: "")
	}
}

class RepoPodMeta {	
	internal	Str:Str		meta
	
	new make(Str:Str meta) { this.meta = meta }
	
	@Operator
	Str get(Str key) {
		meta[key]
	}
	
	@Operator
	Void set(Str key, Str val) {
		meta[key] = val
	}
}