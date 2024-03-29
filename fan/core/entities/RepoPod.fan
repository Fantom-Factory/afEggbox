using afIoc::Inject
using afIoc::Scope
using afMorphia::Entity
using afMorphia::BsonProp
using fanr::PodSpec
using fandoc::FandocParser
using fandoc::Heading
using fandoc::DocElem
using fandoc::DocNodeId
using fandoc::FandocDocWriter

@Entity { name = "pod" }
class RepoPod {
	@Inject private RepoPodDao?		podDao
	@Inject private RepoUserDao?	userDao
	@Inject internal RepoPodFileDao?podFileDao
	@Inject private InvalidLinks?	invalidLinkFinder
	@Inject private Scope?			scope

	@BsonProp	Str				_id
	@BsonProp	Str?			podName
	@BsonProp	Int[]?			podVersion
	@BsonProp	RepoPodMeta		meta
	@BsonProp	Int				fileSize
	@BsonProp	Int				ownerId
	@BsonProp	Str				aboutFandoc
	@BsonProp	InvalidLink[]	invalidLinks
	@BsonProp	DateTime?		linksValidatedOn

	@BsonProp	Bool			hasApi
	@BsonProp	Bool			hasDocs
	@BsonProp	Bool			hasIcon
	@BsonProp	Str?			iconDataUri

	new make(|This|f) { f(this) }

	static new fromContents(RepoUser user, Int podSize, Str:Str metaProps, Uri:Buf docContents, Str[] rootFileNames) {
		return RepoPod() {
			it.meta			= RepoPodMeta(metaProps)
			it.fileSize		= podSize
			it.ownerId		= user._id
			it.aboutFandoc	= findAboutFandoc(docContents)
			it.invalidLinks	= InvalidLink#.emptyList
			it.hasDocs		= docContents.containsKey(`/doc/pod.fandoc`)
			it.hasIcon		= docContents.containsKey(`/doc/icon.png`) || docContents.containsKey(`/doc/icon.svg`)
			
			if (docContents.containsKey(`/doc/icon.png`)) {
				it.hasIcon = true
				if (docContents[`/doc/icon.png`].size < 12*1024)
					it.iconDataUri	= "data:image/png;base64," + docContents[`/doc/icon.png`].toBase64
			}

			if (docContents.containsKey(`/doc/icon.svg`))
				if (docContents[`/doc/icon.svg`].size < 12*1024) {
					// ALL SVGs must be < 12Kb and rendered inline
					// Why? Because I can't be arsed chaning the DB property and migrating the data!
					// Maybe for Eggbox v2...
					it.hasIcon = true
					it.iconDataUri	= "data:image/svg+xml;base64," + docContents[`/doc/icon.svg`].toBase64
				}
			
			if (rootFileNames.contains("${meta.name}.js"))
				it.meta.jsEnabled = true
			
			it._id			= "${name}-${version}".lower
			it.podName		= meta.name
			it.podVersion	= meta.version.segments.rw
			while (it.podVersion.size < 4)
				it.podVersion.add(0)
		}
	}
	
	** Used by PodSummaryPage
	Depend depend() {
		Depend("$name $version")
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
	
	Str summaryHtml() {
		summary := meta.summary.toXml
		if (meta.isDeprecated)
			summary += " <span class=\"text-muted\">(Deprecated)</span>"
		if (meta.isInternal)
			summary += " <span class=\"text-muted\">(Internal)</span>"
		return summary
	}
	
	Depend[] dependsOn() {
		meta["pod.depends"].toStr.split(';').map { Depend(it, false) }.exclude { it == null }.sort |Depend p1, Depend p2 -> Int| { p1.name <=> p2.name }
	}
	
	RepoUser owner() {
		userDao[ownerId]
	}
	
	FandocSummaryUri toSummaryUri() {
		scope.build(FandocSummaryUri#, [name, version])
	}

	FandocApiUri toApiUri(Str? typeName := null, Str? slotName := null) {
		scope.build(FandocApiUri#, [name, version, typeName, slotName])
	}

	FandocSrcUri toSrcUri(Str typeName, Str? slotName := null) {
		scope.build(FandocSrcUri#, [name, version, typeName, slotName])
	}

	FandocDocUri toDocUri(Uri fileUri := `/doc/pod.fandoc`, Str? headingId := null) {
		scope.build(FandocDocUri#, [name, version, fileUri, headingId])
	}
	
	Uri toAtomFeedUrl() {
		toSummaryUri.toClientUrl.plusSlash.plusName("feed.atom")
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
	
	private Str findAboutFandoc(Uri:Buf contents) {
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
		
		return ""
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

		// FIXME we shouldn't alter the pod meta, but instead keep our own copy
		// pod-meta is only used for (unsupported) fanr searching - so we could kill it and
		// default project name to pod name (if not supplied)
		if (get("pod.dis") == null)
			projectName = name

		// convert private to public
		if (metaOrig.containsKey("repo.private")) {
			set("repo.public", (meta["repo.private"].toStr.toBool(false) ?: true).not.toStr)
			meta.remove("repo.private")
		} else {
			// older pods from Repo302 should default to public, newer pods to private
			if (!metaOrig.containsKey("repo.public")) {
				date := DateTime.fromStr(metaOrig["build.ts"]).date
				pub  := date < Date(2015, Month.jun, 1)
				set("repo.public", pub)
			}
		}

		// respect both British and American spellings - but use / keep the British one!
		if (metaOrig.containsKey("license.name")) {
			licenceName = metaOrig["license.name"]
			meta.remove("license.name")
		}

		// ensure these guys exist for indexing / convert to Bool
		set("repo.public", 		get("repo.public")		?.toStr?.toBool(false) ?: false)
		set("build.ts",			DateTime.fromStr(get("build.ts").toStr))
		
		// convert other props to Bool
		meta.keys.each |key| {
			if (meta[key].toStr.toBool(false) != null)
				meta[key] = meta[key].toStr.toBool	
		}

		try parseTest := podUrl
		catch podUrl = null

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
		get { get("repo.deprecated") ?: false }
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
	
	// TODO rename projectName this to dis - check slim templates
	Str projectName {
		get {
			nom := get("pod.dis")
			// small hack so I don't have to update all 55 of my public pods!
			if (nom == null && orgName == "Alien-Factory")
				nom = get("pod.displayName") ?: get("proj.name")
			return nom ?: name
		}
		set { set("pod.dis", it)	}
	}

	Uri? podUrl {
		get { get("pod.uri")?.toStr?.toUri ?: get("proj.uri")?.toStr?.toUri }
		set { set("pod.uri", it?.toStr)	}
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

	Str[] tags {
		get { get("repo.tags")?.toStr?.split(',') ?: Str#.emptyList }
		set { set("repo.tags", it.join(", "))	}
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
	@BsonProp	const FandocUri	where
	@BsonProp	const Str		link
	@BsonProp	const Str		msg

	new make(|This|in) { in(this) }
	
	override Str toStr() {
		"$link - $msg"
	}
}

