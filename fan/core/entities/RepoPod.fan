using afIoc
using afMorphia
using fandoc
using fanr

@Entity { name = "pod" }
class RepoPod {
	@Inject private RepoPodDao?		podDao
	@Inject private RepoUserDao?	userDao
	@Inject internal RepoPodFileDao?podFileDao
	@Inject private InvalidLinks?	invalidLinkFinder
	@Inject private Registry?		registry

	@Property{}	Str?			_id
	@Property{}	RepoPodMeta		meta
	@Property{}	Int				fileSize
	@Property{}	Int				ownerId
	@Property{}	Str				aboutFandoc
	@Property{}	InvalidLink[]	invalidLinks
	@Property{}	DateTime?		linksValidatedOn

	new make(|This|f) { f(this) }

	static new fromContents(RepoUser user, Int podSize, Str:Str metaProps, Uri:Buf docContents) {
		return RepoPod() {
			it.meta			= RepoPodMeta(metaProps)
			it.fileSize		= podSize
			it.ownerId		= user._id
			it.aboutFandoc	= findAboutFandoc(metaProps, docContents)
			it.invalidLinks	= InvalidLink#.emptyList
		}
	}
	
	This save() {
		(RepoPod) podDao.update(this)
	}
	
	This validateDocumentLinks() {
		invalidLinks = invalidLinkFinder.findInvalidLinks(this)
		linksValidatedOn = DateTime.now
		return this
	}

	Str[] validateForPublicUse() {
		errs := Str[,]
		RepoPodMeta.specialKeys.each |key| {
			if (meta[key] == null || meta[key].toStr.isEmpty)
				errs.add(Msgs.publish_missingPodMeta(key))
		}
		
		if (meta.licenceName == null || meta.licenceName.isEmpty)
			errs.add(Msgs.publish_missingPublicPodMeta("licence.name' or 'license.name"))

		if ((meta.vcsUrl == null || meta.vcsUrl.toStr.isEmpty) && (meta.orgUrl == null || meta.orgUrl.toStr.isEmpty))
			errs.add(Msgs.publish_missingPublicPodMeta("vcs.uri' or 'org.uri"))
		
		return errs
	}

	Str:Str toJsonObj() {
		meta.meta
	}
	
	PodSpec toPodSpec() {
		PodSpec(toJsonObj, null)
	}
	
	Buf loadFile() {
		podFileDao.get(_id, true).data
	}
	
	Str summary() {
		summary := meta.summary
		if (meta.isDeprecated)
			summary = "(Deprecated) ${summary}"
		if (meta.isInternal)
			summary = "(Internal) ${summary}"
		return summary
	}
	
	Depend[] dependsOn() {
		meta["pod.depends"].toStr.split(';').map { Depend(it, false) }.exclude { it == null }.sort |Depend p1, Depend p2 -> Int| { p1.name <=> p2.name }
	}
	
	RepoUser owner() {
		userDao[ownerId]
	}
	
	FandocSummaryUri toSummaryUri() {
		registry.autobuild(FandocSummaryUri#, [name, version])
	}
	
	Str name() {
		meta.name
	}
	
	Version version() {
		meta.version
	}
	
	DateTime builtOn() {
		meta.builtOn
	}
	
	Str projectName() {
		meta.projectName
	}
	
	Bool isPublic() {
		meta.isPublic
	}
	
	Bool isDeprecated() {
		meta.isDeprecated
	}
	
	private Str findAboutFandoc(Str:Str metaProps, Uri:Buf contents) {
		aboutFd := contents[`/doc/about.fandoc`]?.readAllStr ?: contents[`/doc/about.fdoc`]?.readAllStr		
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
		
		return metaProps["summary"] ?: "This pod has no description"
	}
	
	override Str toStr() { _id }
	
	override Int hash() { _id.toInt }
	override Bool equals(Obj? that) {
		_id == (that as RepoPod)?._id
	}
}

class RepoPodMeta {	
	static const	
	Str[] 		specialKeys	:= ["pod.name", "pod.version", "pod.depends", "pod.summary", "build.ts"]
	Str:Obj?	meta	// allow some MongoDB types to be stored
	
	new make(|This|in) { in(this) }

	new makeFromOrig(Str:Str metaOrig) {
		specialKeys.each { assertKeyExists(metaOrig, it) }

		meta = Str:Str[:] { ordered = true }
		specialKeys.each { meta[it] = metaOrig[it] ?: "" }
		metaOrig.keys.exclude { specialKeys.contains(it) }.sort.each { meta[it] = metaOrig[it] }

		// default project name to pod name (if not supplied)
		if (get("proj.name") == null)
			projectName = name.toDisplayName	// so sys -> Sys
		
		// convert private to public
		if (metaOrig.containsKey("repo.private")) {
			set("repo.public", (meta["repo.private"].toStr.toBool(false) ?: true).not.toStr)
			meta.remove("repo.private")
		}

		// respect both British and American spellings - but use / keep the British one!
		if (metaOrig.containsKey("license.name")) {
			licenceName = metaOrig["license.name"]
			meta.remove("license.name")
		}
		
		// ensure these guys exist for indexing / convert to Bool
		set("repo.public", 		get("repo.public")		?.toStr?.toBool(false) ?: false)
		set("repo.deprecated",	get("repo.deprecated")	?.toStr?.toBool(false) ?: false)
		set("build.ts",			DateTime.fromStr(get("build.ts").toStr))
		
		// convert other props to Bool
		"pod.docApi pod.docSrc pod.isScript pod.native.dotnet pod.native.java pod.native.jni pod.native.js repo.internal repo.jsEnabled".split.each {
			if (containsKey(it))
				set(it,	this.get(it)?.toStr?.toBool(false) ?: false)			
		}

		try parseTest := projectUrl
		catch projectUrl = null

		try parseTest := orgUrl
		catch orgUrl = null
		
		try parseTest := vcsUrl
		catch vcsUrl = null
	}

	Bool isPublic {
		get { get("repo.public")	}
		set { set("repo.public", it) }
	}

	Bool isDeprecated {
		get { get("repo.deprecated")	}
		set { set("repo.deprecated", it) }
	}

	Bool isInternal {
		get { get("repo.internal") ?: false	}
		set { set("repo.internal", it)		}
	}

	Str name {
		get { get("pod.name") 			}
		set { set("pod.name", it)		}
	}

	Version version {
		get { Version(get("pod.version").toStr)	}
		set { set("pod.version", it.toStr)		}
	}

	Str summary {
		get { get("pod.summary")		}
		set { set("pod.summary", it)	}
	}

	DateTime builtOn {
		get { get("build.ts")			}
		private set { /* read only */	}
	}
	
	Str projectName {
		get { get("proj.name")			}
		set { set("proj.name", it)		}
	}

	Uri? projectUrl {
		get { get("proj.uri")?.toStr?.toUri	}
		set { set("proj.uri", it?.toStr)	}
	}
	
	Str? licenceName {
		get { get("licence.name")		}
		set { set("licence.name", it)	}
	}

	Str? orgName {
		get { get("org.name")			}
		set { set("org.name", it)		}
	}

	Uri? orgUrl {
		get { get("org.uri")?.toStr?.toUri	}
		set { set("org.uri", it?.toStr)		}
	}

	Str? vcsName {
		get { get("vcs.name")			}
		set { set("vcs.name", it)		}
	}

	Uri? vcsUrl {
		get { get("vcs.uri")?.toStr?.toUri	}
		set { set("vcs.uri", it?.toStr)		}
	}

	Str? tags {
		get { get("repo.tags")			}
		set { set("repo.tags", it)		}
	}

	Bool jsEnabled {
		get { get("repo.jsEnabled") ?: false }
		set { set("repo.jsEnabled", it)		 }
	}

	@Operator
	Obj? get(Str key) {
		meta.get(key)
	}
	
	@Operator
	Void set(Str key, Obj? value) {
		val := value is Str ? value.toStr.trimToNull : value
		if (val == null)
			meta.remove(key)
		else
			meta[key] = val
	}
	
	Bool containsKey(Str key) {
		meta.containsKey(key)
	}
	
	private static Void assertKeyExists(Str:Str meta, Str key) {
		if (key != "pod.summary")	// we'll set 'pod.summary' to "", which is fine for private pods 
			if (meta[key] == null || meta[key].isEmpty)
				throw PodPublishErr(Msgs.publish_missingPodMeta(key))
	}
}

const class InvalidLink {
	@Property{} const FandocUri	where
	@Property{}	const Str		link
	@Property{}	const Str		msg

	new make(|This|in) { in(this) }
	
	override Str toStr() {
		"$link - $msg"
	}
}