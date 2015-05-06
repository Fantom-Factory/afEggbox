using afIoc
using afMorphia
using fandoc
using fanr

@Entity { name = "pod" }
class RepoPod {
	@Inject private const RepoPodFileDao?	podFileDao

	@Property{}	Str?		_id
	@Property{}	Str			name
	@Property{}	Version		version
	@Property{}	Int			fileSize
	@Property{}	DateTime	builtOn
	@Property{}	Bool		isPublic
	@Property{}	Uri			ownerId
	@Property{}	Str			aboutFandoc
	@Property{}	RepoPodMeta	meta

	@Inject
	new make(|This|f) { f(this) }
	
	static new fromFile(File podFile, RepoUser user) {
		zip	:= Zip.open(podFile)
		try {
			props 	:= zip.contents[`/meta.props`]?.readProps ?: throw Err("Missing meta.props")
			meta	:= RepoPodMeta(podFile.name, props)

			return RepoPod() {
				it.name			= meta["pod.name"]
				it.fileSize		= podFile.size
				it.version		= Version(meta["pod.version"])
				it.meta			= meta
				it.aboutFandoc	= findAboutFandoc(zip)
				it.isPublic		= false	// FIXME: isPublic
				it.ownerId		= user.email
			}

		} finally {
			zip.close
		}
	}
	
	Str:Obj toJsonObj() {
		meta.meta
	}
	
	PodSpec toPodSpec() {
		PodSpec(meta.meta, null)
	}
	
	Buf loadFile() {
		podFileDao.get(_id, true).data
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
	static const	
	private 	Str[] 	specialKeys	:= ["pod.name", "pod.version", "pod.depends", "pod.summary"]
	internal	Str:Str	meta
	
	new make(Str:Str meta) {
		specialKeys.each { assertKeyExists(null, meta, it) }
		this.meta = meta
	}

	new makeAndSort(Str fileName, Str:Str meta) {
		specialKeys.each { assertKeyExists(fileName, meta, it) }

		m := Str:Str[:] { ordered = true }
		specialKeys.each { m[it] = meta[it] }
		meta.keys.exclude { specialKeys.contains(it) }.sort.each { m[it] = meta[it] }
		
		this.meta = m
	}
	
	Str summary() {
		meta["pod.summary"]
	}
	
	@Operator
	Str get(Str key) {
		meta[key]
	}
	
	@Operator
	Void set(Str key, Str val) {
		meta[key] = val
	}
	
	private static Void assertKeyExists(Str? fileName, Str:Str meta, Str key) {
		name := fileName != null ? "from '${fileName}' " : ""
		if (!meta.containsKey(key))
			throw Err("Pod meta ${name}should contain the key '${key}' - ${meta}")
	}
}