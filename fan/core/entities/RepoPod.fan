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
	@Property{}	Str				name
	@Property{}	Version			version
	@Property{}	Int				fileSize
	@Property{}	DateTime		builtOn
	@Property{}	Int				ownerId
	@Property{}	Str				aboutFandoc
	@Property{}	Bool			isPublic		// keep our own 'isPublic' for indexing and searching on
	@Property{}	Bool			isDeprecated	// keep our own 'isDeprecated' for indexing and searching on
				Str				displayName {
					get { "${name} ${version}" }
					private set { }
				}
	@Property{}	InvalidLink[]	invalidLinks
	@Property{}	DateTime?		linksValidatedOn
	@Property private Str:Str	metaOrig			// currently we don't need 2 meta maps, but it's good future proofing
	@Property private Str:Str?	metaNew			// should we decide to validate on the original meta, such as only
				RepoPodMeta		meta			// allowing pod to be public if the uploaded meta is valid

	new make(|This|f) {
		f(this)
		meta = RepoPodMeta(metaOrig, metaNew)
	}
	
	static new fromContents(RepoUser user, Int podSize, Str:Str metaProps, Uri:Buf docContents) {
		meta := RepoPodMeta(metaProps.ro)
		return RepoPod() {
			it.name			= meta["pod.name"]
			it.fileSize		= podSize
			it.version		= Version(meta["pod.version"])
			it.builtOn		= DateTime(meta["build.ts"], true)
			it.meta			= meta
			it.aboutFandoc	= findAboutFandoc(metaProps, docContents)
			it.&isPublic	= meta.isPublic		// don't worry if the two get out of sync, we only use the non-meta one
			it.&isDeprecated= meta.isDeprecated	// don't worry if the two get out of sync, we only use the non-meta one
			it.ownerId		= user._id
			it.invalidLinks	= InvalidLink#.emptyList
			it.metaOrig 	= meta.metaOrig	// this map has been nicely ordered
			it.metaNew 		= meta.metaNew
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
		meta.allMeta
	}
	
	PodSpec toPodSpec() {
		PodSpec(toJsonObj, null)
	}
	
	Buf loadFile() {
		podFileDao.get(_id, true).data
	}
	
	Str projectName() {
		meta.projectName
	}
	
	Str summary() {
		summary := meta.summary
		if (isDeprecated)
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
	
	override Str toStr() { "${name}-${version}" }
	
	override Int hash() { _id.toInt }
	override Bool equals(Obj? that) {
		_id == (that as RepoPod)?._id
	}
}

class RepoPodMeta {	
	static const	
	Str[] 		specialKeys	:= ["pod.name", "pod.version", "pod.depends", "pod.summary", "build.ts"]
	Str:Str		metaOrig
	Str:Str?	metaNew
	
	new make(Str:Str metaOrig, Str:Str? metaNew) {
		this.metaOrig	= metaOrig
		this.metaNew	= metaNew
	}

	new makeFromOrig(Str:Str metaOrig) {
		specialKeys.each { assertKeyExists(metaOrig, it) }

		m2 := Str:Str[:] { ordered = true }
		specialKeys.each { m2[it] = metaOrig[it] ?: "" }
		metaOrig.keys.exclude { specialKeys.contains(it) }.sort.each { m2[it] = metaOrig[it] }
		
		this.metaOrig	= m2.toImmutable
		this.metaNew	= Str:Str?[:] { ordered = true }

		// respect both British and American spellings - but use / keep the British one!
		if (metaOrig.containsKey("license.name"))
			metaNew["licence.name"] = metaOrig["license.name"]
		
		try parseTest := projectUrl
		catch projectUrl = null

		try parseTest := orgUrl
		catch orgUrl = null
		
		try parseTest := vcsUrl
		catch vcsUrl = null
	}

	Bool isPublic {
		// convert the older "repo.private" --> "repo.public"
		get { get("repo.public")?.toBool(false) ?: !(get("repo.private")?.toBool(false) ?: false) }
		private set { }
	}

	Bool isDeprecated {
		get { get("repo.deprecated")?.toBool(false) ?: false }
		private set { }
	}

	Bool isInternal {
		get { get("repo.internal")?.toBool(false) ?: false }
		set { set("repo.internal", it)	}
	}

	Str summary {
		get { get("pod.summary") ?: ""	}
		set { set("pod.summary", it)	}
	}
	
	Str projectName {
		get { get("proj.name") ?: get("pod.name") }
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
		metaNew.containsKey(key) ? metaNew[key] : metaOrig[key]
	}
	
	@Operator
	Void set(Str key, Obj? value) {
		val := value?.toStr?.trimToNull
		if (metaOrig.containsKey(key) && metaOrig[key] == val) {
			metaNew.remove(key)
			return
		}
		metaNew[key] = val
	}
	
	Bool containsKey(Str key) {
		metaNew.containsKey(key) || metaOrig.containsKey(key)
	}
	
	Str:Str allMeta() {
		if (metaNew.isEmpty)
			return metaOrig
		// add the two meta maps together but try to keep the original key order
		meta := Str:Str[:] { ordered = true}
		metaOrig.keys.addAll(metaNew.keys).unique.each |key| {
			meta[key] = get(key)
		}
		return meta
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