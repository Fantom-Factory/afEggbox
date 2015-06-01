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
			if (meta[key] == null || meta[key].isEmpty)
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
		meta["pod.depends"].split(';').map { Depend(it, false) }.exclude { it == null }.sort |Depend p1, Depend p2 -> Int| { p1.name <=> p2.name }
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
	Str:Str?	meta
	
	new make(|This|in) { in(this) }

	new makeFromOrig(Str:Str metaOrig) {
		specialKeys.each { assertKeyExists(metaOrig, it) }

		meta = Str:Str[:] { ordered = true }
		specialKeys.each { meta[it] = metaOrig[it] ?: "" }
		metaOrig.keys.exclude { specialKeys.contains(it) }.sort.each { meta[it] = metaOrig[it] }

		// default project name to pod name
		if (get("proj.name") == null)
			projectName = name
		
		// convert private to public
		if (metaOrig.containsKey("repo.private")) {
			isPublic = !(meta["repo.private"]?.toBool(false) ?: false)
			meta.remove("repo.private")
		}

		// respect both British and American spellings - but use / keep the British one!
		if (metaOrig.containsKey("license.name")) {
			licenceName = metaOrig["license.name"]
			meta.remove("license.name")
		}
		
		// ensure these guys exist for indexing
		isPublic		= |->Obj| { isPublic	 }()
		isDeprecated	= |->Obj| { isDeprecated }()

		try parseTest := projectUrl
		catch projectUrl = null

		try parseTest := orgUrl
		catch orgUrl = null
		
		try parseTest := vcsUrl
		catch vcsUrl = null
	}

	Bool isPublic {
		// convert the older "repo.private" --> "repo.public"
		get { get("repo.public")?.toBool(false) ?: false}
		set { set("repo.public", it.toStr) }
	}

	Bool isDeprecated {
		get { get("repo.deprecated")?.toBool(false) ?: false }
		set { set("repo.deprecated", it.toStr) }
	}

	Bool isInternal {
		get { get("repo.internal")?.toBool(false) ?: false }
		set { set("repo.internal", it)	}
	}

	Str name {
		get { get("pod.name") 			}
		set { set("pod.name", it)		}
	}

	Version version {
		get { Version(get("pod.version"))	}
		set { set("pod.version", it.toStr)	}
	}

	Str summary {
		get { get("pod.summary")		}
		set { set("pod.summary", it)	}
	}

	DateTime builtOn {
		get { DateTime(get("build.ts"))	}
		private set { }
	}
	
	Str projectName {
		get { get("proj.name")			}
		set { set("proj.name", it)		}
	}

	Uri? projectUrl {
		get { get("proj.uri")?.toUri	}
		set { set("proj.uri", it)		}
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
		get { get("org.uri")?.toUri		}
		set { set("org.uri", it)		}
	}

	Str? vcsName {
		get { get("vcs.name")			}
		set { set("vcs.name", it)		}
	}

	Uri? vcsUrl {
		get { get("vcs.uri")?.toUri		}
		set { set("vcs.uri", it)		}
	}

	Str? tags {
		get { get("repo.tags")			}
		set { set("repo.tags", it)		}
	}
		
	@Operator
	Str? get(Str key) {
		meta[key]
	}
	
	@Operator
	Void set(Str key, Obj? value) {
		val := value?.toStr?.trimToNull
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