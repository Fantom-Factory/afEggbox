using afIoc
using afMorphia
using fandoc
using fanr

@Entity { name = "pod" }
class RepoPod {
	@Inject private const RepoUserDao?		userDao
	@Inject private const RepoPodFileDao?	podFileDao

	@Property{}	Str?		_id
	@Property{}	Str			name
	@Property{}	Version		version
	@Property{}	Int			fileSize
	@Property{}	DateTime	builtOn
	@Property{}	Bool		isPublic
	@Property{}	Int			ownerId
	@Property{}	Str			aboutFandoc
	@Property{}	RepoPodMeta	meta

				Str			displayName {
					get { "${name} ${version}" }
					private set { }
				}

	new make(|This|f) { f(this) }
	
	static new fromContents(RepoUser user, Int podSize, Str:Str metaProps, Uri:Buf docContents) {
		meta := RepoPodMeta(metaProps)
		return RepoPod() {
			it.name			= meta["pod.name"]
			it.fileSize		= podSize
			it.version		= Version(meta["pod.version"])
			it.builtOn		= DateTime(meta["build.ts"], true)
			it.meta			= meta
			it.aboutFandoc	= findAboutFandoc(metaProps, docContents)
			it.isPublic		= meta.isPublic
			it.ownerId		= user._id
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
	
	RepoUser owner() {
		userDao[ownerId]
	}
	
	private Str findAboutFandoc(Str:Str metaProps, Uri:Buf contents) {
		aboutFd := contents[`/doc/about.fdoc`]?.readAllStr		
		if (aboutFd != null)
			return aboutFd
		
		if (contents[`/doc/pod.fandoc`] != null) {
			podFd := contents[`/doc/pod.fandoc`].readAllStr
			
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
		
		return metaProps["summary"] ?: (metaProps["podName"] ?: "???")
	}
	
	override Str toStr() { "${name}-${version}" }
	
	override Int hash() { _id.toInt }
	override Bool equals(Obj? that) {
		_id == (that as RepoPod)._id
	}
}

class RepoPodMeta {	
	static const	
	private 	Str[] 	specialKeys	:= ["pod.name", "pod.version", "pod.depends", "pod.summary", "build.ts"]
	internal	Str:Str	meta
	
	new make(Str:Str meta) {
		specialKeys.each { assertKeyExists(meta, it) }

		m := Str:Str[:] { ordered = true }
		specialKeys.each { m[it] = meta[it] }
		meta.keys.exclude { specialKeys.contains(it) }.sort.each { m[it] = meta[it] }
		
		this.meta = m
	}
	
	Str summary() {
		meta["pod.summary"]
	}
	
	Str projectName() {
		meta["proj.name"] ?: meta["pod.name"]
	}
	
	Bool isPublic() {
		if (meta.containsKey("repo.public"))
			return Bool.fromStr(meta["repo.public"] ?: "false", false) ?: false
		if (meta.containsKey("repo.private"))
			return !(Bool.fromStr(meta["repo.private"] ?: "true", false) ?: true)
		return false
	}

	Str? licenceName() {
		meta["licence.name"] ?: meta["license.name"]
	}

	Str? vcsUrl() {
		meta["vcs.uri"]
	}
	
	Str? orgUrl() {
		meta["org.uri"]
	}
	
	@Operator
	Str? get(Str key) {
		meta[key]
	}
	
	@Operator
	Void set(Str key, Str val) {
		meta[key] = val
	}
	
	Bool containsKey(Str key) {
		meta.containsKey(key)
	}
	
	private static Void assertKeyExists(Str:Str meta, Str key) {
		if (!meta.containsKey(key))
			throw PodPublishErr(Msgs.publish_missingPodMeta(key))
	}
}