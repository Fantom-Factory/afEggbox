using afIoc
using fandoc
using concurrent

internal const class FandocLinkResolver : LinkResolver {

	@Inject private const Registry	reg
	
	new make(|This|in) { in(this) }
	
	override Uri? resolve(Str str, LinkResolverCtx ctx) {
		uri := str.toUri
		if (uri.scheme != "fandoc") return null

		fandocUri := FandocUri.fromUri(reg, uri)
		if (fandocUri == null)
			return null
		
		if (fandocUri.validate == false)
			return null
		
		if (fandocUri is FandocDocUri && ((FandocDocUri) fandocUri).isAsset)
			return ((FandocDocUri) fandocUri).toAsset.clientUrl

		return fandocUri.toClientUrl
	}
}








abstract const class FandocUri {
	@Inject const FandocWriter	fandocRenderer
	@Inject const Registry		reg
	@Inject const RepoPodDao	podDao
	@Inject const CorePods		corePods
			const Str 			podName
			const Version?		podVersion

	protected new make(Str podName, Version? podVersion, |This| in) {
		this.podName 	= podName
		this.podVersion	= podVersion
		in(this)
	}
	
	static new fromUri(Registry reg, Uri uri) {
		if (uri.auth != null || uri.path.isEmpty)
			return null

		path 		:= uri.path.rw
		podName		:= chomp(path)
		podVersion	:= Version(uri.query["v"] ?: "", false)
		
		return parsePath(reg, uri, podName, podVersion, path)
	}
	
	static new fromClientUrl(Registry reg, Uri uri) {
		path 		:= uri.pathOnly.path.rw
		pods		:= chomp(path)
		podName		:= chomp(path)
		podVersion	:= Version((path.isEmpty ? null : path.first) ?: "", false)
		if (podVersion != null)	chomp(path)
		
		if (pods != "pods")
			return InvalidLinks.add(InvalidLinkMsgs.pathSegmentNotPods(pods))

		return parsePath(reg, uri, podName, podVersion, path)
	}
	
	private static FandocUri? parsePath(Registry reg, Uri uri, Str? podName, Version? podVersion, Str[] path) {
		if (podName == null)
			return InvalidLinks.add(InvalidLinkMsgs.invalidPodName(podName))

		if (path.isEmpty)
			return reg.autobuild(FandocSummaryUri#, [podName, podVersion])

		section	:= chomp(path)
		if (section == "api") {
			typeName := chomp(path)
			slotName := uri.frag
			if (slotName?.contains("?") ?: false) {
				podVersion = Version(slotName.toUri.query["v"] ?: "", false) ?: podVersion
				slotName = slotName.toUri.pathStr	// remove any querystring from the frag - happens if frag is written before the query (which is wrong!)
			}
			if (path.isEmpty)
				return reg.autobuild(FandocApiUri#, [podName, podVersion, typeName, slotName])
			src := path.first
			if (src == "src")
				return reg.autobuild(FandocSrcUri#, [podName, podVersion, typeName, slotName])
			return InvalidLinks.add(InvalidLinkMsgs.tooManyPathSegments(path))
		}

		if (section == "src") {
			typeName := chomp(path)
			if (!path.isEmpty)
				InvalidLinks.add(InvalidLinkMsgs.tooManyPathSegments(path))
			slotName := uri.frag
			return reg.autobuild(FandocSrcUri#, [podName, podVersion, typeName, slotName])
		}

		if (section == "doc") {
			docUri := (Uri) path.reduce(`/doc/`) |Uri docUri, seg->Uri| { docUri.plusSlash.plusName(seg) }
			if (docUri == `/doc/`)
				docUri = docUri.plusName("pod.fandoc")
			if (docUri.ext == null)
				docUri = (docUri.toStr + ".fandoc").toUri
			headingId := uri.frag
			return reg.autobuild(FandocDocUri#, [podName, podVersion, docUri, headingId])
		}

		return InvalidLinks.add(InvalidLinkMsgs.invalidPathSegment(section))
	}

	static new fromFantomUri(Registry reg, LinkResolverCtx ctx, Str link) {
		uri := link.toUri
		if (link.contains("::")) {
			if (link.split(':').size > 3)
				return InvalidLinks.add(InvalidLinkMsgs.invalidFantomUri)
			podName		:= link.split(':').first
			typeName	:= link[podName.size+2..-1]
			return parseFantomUri(reg, ctx, link, podName, typeName)
		}
		
		if (uri.scheme == null && !uri.isPathAbs) {
			if (ctx.pod != null)
				return parseFantomUri(reg, ctx, link, ctx.pod.name, link)
		}
		
		return null
	}
	
	private static FandocUri? parseFantomUri(Registry reg, LinkResolverCtx ctx, Str str, Str podName, Str typeName) {
		uri := str.toUri
		if (typeName == "index" || typeName.isEmpty)
			return reg.autobuild(FandocSummaryUri#, [podName, null])
		if (typeName == "pod-doc")
			return reg.autobuild(FandocDocUri#, [podName, null, `/doc/pod.fandoc`, null])

		if (typeName.startsWith("src-"))
			return reg.autobuild(FandocSrcUri#, [podName, null, typeName[4..-1], null])
		
		
		podDao 		:= (RepoPodDao)		reg.serviceById(RepoPodDao#.qname)
		podApiDao	:= (RepoPodApiDao)	reg.serviceById(RepoPodApiDao#.qname)
		corePods	:= (CorePods) 		reg.serviceById(CorePods#.qname)
		
		// if the context has the same pod name, use the same pod version too 
		pod 		:= (podName == ctx.pod?.name) ? ctx.pod : podDao.findOne(podName)

		if (pod == null && corePods.isCorePod(podName)) {
			if (typeName[0].isLower || uri.frag != null) {
				docUri := `/doc/` + typeName.toUri.pathOnly
				if (docUri.ext == null)
					docUri = `${docUri}.fandoc`
				headingId := uri.frag
				return reg.autobuild(FandocDocUri#, [podName, null, docUri, headingId])
			}
			slotName := (Str?) null
			if (typeName.contains(".") && typeName.split('.').size == 2 && typeName[0].isUpper) {
				slotName = typeName.split('.').getSafe(1)
				typeName = typeName.split('.').getSafe(0)
			}
			return reg.autobuild(FandocApiUri#, [podName, null, typeName, slotName])
		}

		if (pod == null)
			return InvalidLinks.add(InvalidLinkMsgs.podNotFound(podName, null))
		
		podApi := pod.hasApi ? podApiDao[pod._id] : null
		if (podApi != null && podApi.hasType(typeName.split('.')[0])) {
			slotName	:= (Str?) null
			if (typeName.contains(".")) {
				if (typeName.split('.').size > 2)
					InvalidLinks.add(InvalidLinkMsgs.invalidTypeSlotCombo)
				else {
					slotName = typeName.split('.').getSafe(1)
					typeName = typeName.split('.').getSafe(0)
				}
			}
			return reg.autobuild(FandocApiUri#, [pod.name, pod.version, typeName, slotName])
		}

		if (ctx.type != null && podApi != null && podApi.hasType(ctx.type))
			if (podApi[ctx.type].slot(typeName, false) != null)
				return reg.autobuild(FandocApiUri#, [pod.name, pod.version, ctx.type, typeName])
		
		docUri := `/doc/` + typeName.toUri.pathOnly
		if (docUri.ext == null)
			docUri = `${docUri}.fandoc`
		headingId := uri.frag
		return reg.autobuild(FandocDocUri#, [pod.name, pod.version, docUri, headingId])
	}
	
	private Uri summaryUrl(RepoPod pod) {
		url := `/pods`
		url = url.plusSlash.plusName(pod.name).plusSlash
		return url
	}

	private static Str? chomp(Str[] path) {
		path.isEmpty ? null : path.removeAt(0) 
	}

	Bool isLatest() {
		podVersion == null || podVersion == podDao.findOne(podName)?.version
	}

	Bool isCorePod() {
		podDao.findOne(podName, podVersion) == null && corePods.isCorePod(podName)
	}

	abstract FandocUri? toParentUri()
	abstract FandocUri toLatest()

	FandocSummaryUri toSummaryUri() {
		this is FandocSummaryUri
			? this
			: reg.autobuild(FandocSummaryUri#, [podName, podVersion])
	}

	FandocApiUri toApiUri(Str? typeName := null, Str? slotName := null) {
		reg.autobuild(FandocApiUri#, [podName, podVersion, typeName, slotName])
	}

	FandocSrcUri toSrcUri(Str typeName, Str? slotName := null) {
		reg.autobuild(FandocSrcUri#, [podName, podVersion, typeName, slotName])
	}

	FandocDocUri toDocUri(Uri fileUri := `/doc/pod.fandoc`, Str? headingId := null) {
		reg.autobuild(FandocDocUri#, [podName, podVersion, fileUri, headingId])
	}
	
	Uri toAtomFeedUrl() {
		toSummaryUri.toClientUrl.plusSlash.plusName("feed.atom")
	}
	
	protected Bool? validatePod(|RepoPod->Bool?| func) {
		pod := pod
		if (pod == null) {
			InvalidLinks.add(InvalidLinkMsgs.podNotFound(podName, podVersion))
			return false
		}
		return func(pod) ?: false
	}
	
	RepoPod? pod() {
		podDao.findOne(podName, podVersion)
	}
	
	Str etag() {
		"${pod.fileSize.toHex}-${pod.builtOn.ticks.toHex}"
	}
	
	abstract Str title()
	
	abstract Bool validate()
	
	protected abstract Uri? baseUri()
	
	virtual Uri toUri() {
		bse := baseUri
		uri := bse == null ? `fandoc:/${podName}/` : `fandoc:/${podName}/` + bse
		ver := podVersion != null ? podVersion : podDao.findOne(podName)?.version
		return ver == null ? uri : uri.plusQuery(["v":ver.toStr])
	}

	virtual Uri toClientUrl() {
		url := baseUri
		latestPod := podDao.findOne(podName)
		path := (podVersion == null || podVersion == latestPod.version) 
			? `/pods/${podName}/` 
			: `/pods/${podName}/${podVersion}/`
		return (url == null) ? path : path + url
	}
}

const class FandocSummaryUri : FandocUri {

	new make(Str podName, Version? podVersion, |This| in) : super(podName, podVersion, in) { }

	override Bool validate() {
		isCorePod ? true :
		validatePod |pod->Bool| { true }
	}
		
	Str aboutHtml() {
		fandocRenderer.writeStrToHtml(pod.aboutFandoc, LinkResolverCtx(pod))
	}
	
	Uri toDownloadUrl() {
		toClientUrl.plusName("download").plusSlash.plusName("${podName}.pod")
	}
		
	override Str title() {
		"${pod.projectName} ${pod.version}"
	}

	override FandocUri toLatest() {
		reg.autobuild(FandocSummaryUri#, [podName, null])
	}

	override FandocUri? toParentUri() {
		null
	}
	
	override Uri? baseUri() {
		null
	}
	
	override Uri toClientUrl() {
		isCorePod
			? `http://fantom.org/doc/${podName}/index.html`
			: super.toClientUrl
	}
}

const class FandocApiUri : FandocUri {
	@Inject private const RepoPodApiDao	podApiDao
					const Str? 			typeName
					const Str? 			slotName
					const AtomicRef		allDocTypesRef	:= AtomicRef()

	new make(Str podName, Version? podVersion, Str? typeName, Str? slotName, |This| in) : super(podName, podVersion, in) { 
		this.typeName	= typeName
		this.slotName	= slotName
	}
	
	override FandocUri toLatest() {
		reg.autobuild(FandocApiUri#, [podName, null, typeName, slotName])
	}

	DocType type() {
		podApiDao[pod._id][typeName]
	}

	DocSlot slot() {
		type.slot(slotName)
	}

	FandocApiUri[] mixins() {
		allDocTypes.findAll { it.isMixin }.map { toApiUri(it.name) }
	}
	
	FandocApiUri[] classes() {
		allDocTypes.findAll { !it.isMixin && !it.isFacet && !it.isEnum && !it.isErr}.map { toApiUri(it.name) }
	}
	
	FandocApiUri[] enums() {
		allDocTypes.findAll { it.isEnum }.map { toApiUri(it.name) }
	}
	
	FandocApiUri[] facets() {
		allDocTypes.findAll { it.isFacet }.map { toApiUri(it.name) }
	}
	
	FandocApiUri[] errs() {
		allDocTypes.findAll { it.isErr }.map { toApiUri(it.name) }
	}
	
	FandocApiUri[] allTypes() {
		allDocTypes.map { toApiUri(it.name) }
	}

	FandocSrcUri toTypeSrcUri() {
		reg.autobuild(FandocSrcUri#, [podName, podVersion, typeName, null])
	}
	
	FandocSrcUri toSlotSrcUri() {
		reg.autobuild(FandocSrcUri#, [podName, podVersion, typeName, slotName])
	}
	
	Str typeFirstSentenceHtml() {
		type := podApiDao[pod._id][typeName]
		return fandocRenderer.writeStrToHtml(type.doc.firstSentence.text, LinkResolverCtx(pod))
	}

	Str typeHtml() {
		fandocRenderer.writeStrToHtml(type.doc.text, LinkResolverCtx(pod))
	}

	Str slotHtml() {
		fandocRenderer.writeStrToHtml(slot.doc.text, LinkResolverCtx(pod))
	}

	private DocType[] allDocTypes() {
		if (allDocTypesRef.val == null && pod.hasApi)
			allDocTypesRef.val = podApiDao[pod._id].allTypes
				.exclude |DocType t->Bool| {
					t.hasFacet("sys::NoDoc")     ||
					DocFlags.isInternal(t.flags) ||
					DocFlags.isPrivate(t.flags)  ||
					DocFlags.isSynthetic(t.flags)
				}.toImmutable
		return allDocTypesRef.val ?: DocType[,]
	}

	override Bool validate() {
		isCorePod ? true :
		validatePod |RepoPod pod->Bool?| {
			if (typeName == null)
				return true

			// validate Type
			podApi := podApiDao.get(pod._id, false)
			if (podApi == null)
				return InvalidLinks.add(InvalidLinkMsgs.couldNotFindApiFiles(pod))
			type := podApi.get(typeName, false)
			if (type == null)
				return InvalidLinks.add(InvalidLinkMsgs.couldNotFindType(pod, typeName))

			if (slotName == null)
				return true
			
			// validate Slot
			slot := type.slot(slotName, false)
			if (slot == null)
				// return true because the URL is still usable
				InvalidLinks.add(InvalidLinkMsgs.couldNotFindSlot(pod, typeName, slotName))

			return true
		}
	}

	override Uri? baseUri() {
		uri := `api/`
		if (typeName != null)
			uri = uri.plusName(typeName)
		if (slotName != null)
			// this is wrong - '#' is encoded as part of the name, and is not parsed as a fragment 
			// uri = uri.plusName("${uri.name}#${slotName}")
			uri = `${uri}#${slotName}`
		return uri
	}
	
	override Str title() {
		typeName ?: "API"
	}

	override FandocUri? toParentUri() {
		typeName == null
			? toSummaryUri
			: toApiUri
	}
	
	override Uri toClientUrl() {
		if (!isCorePod)
			return super.toClientUrl
		
		if (typeName == null)
			return `http://fantom.org/doc/${podName}/index.html`
		
		fileStr := typeName
		if (fileStr.toUri.ext == null)
			fileStr += ".html"
		return (slotName == null)
			? `http://fantom.org/doc/${podName}/${fileStr}` 
			: `http://fantom.org/doc/${podName}/${fileStr}#${slotName}`
	}
}

const class FandocSrcUri : FandocUri {
	@Inject private const RepoPodApiDao	podApiDao
	@Inject private const RepoPodSrcDao	podSrcDao
	@Inject private const SyntaxWriter	syntaxWriter
					const Str 			typeName
					const Str? 			slotName

	new make(Str podName, Version? podVersion, Str typeName, Str? slotName, |This| in) : super(podName, podVersion, in) { 
		this.typeName = typeName
		this.slotName = slotName
	}

	override FandocUri toLatest() {
		reg.autobuild(FandocSrcUri#, [podName, null, typeName, slotName])
	}

	Str qname() {
		"${podName}::${typeName}"
	}

	Bool hasSrc() {
		validate
	}

	Str srcFile() {
		podApiDao[pod._id][typeName].loc.file
	}
	
	Str src() {
		src	:= podSrcDao[pod._id][srcFile]
		return syntaxWriter.writeSyntax(src, "fan", true)
	}

	override Bool validate() {
		isCorePod ? true :
		validatePod |RepoPod pod->Bool?| {

			// validate Type
			podApi := podApiDao.get(pod._id, false)
			if (podApi == null)
				return InvalidLinks.add(InvalidLinkMsgs.couldNotFindApiFiles(pod))
			type := podApi.get(typeName, false)
			if (type == null)
				return InvalidLinks.add(InvalidLinkMsgs.couldNotFindType(pod, typeName))
			podSrc := podSrcDao.get(pod._id, false)
			if (podSrc == null)
				return InvalidLinks.add(InvalidLinkMsgs.couldNotFindSrcFiles(pod))
			typeSrc := podSrc[type.loc.file]
			if (typeSrc == null)
				return InvalidLinks.add(InvalidLinkMsgs.couldNotFindSrcFile(pod, type.loc.file))
			
			if (slotName == null)
				return true
			
			// validate Slot
			slot := type.slot(slotName, false)
			if (slot == null)
				// return true because the URL is still usable
				InvalidLinks.add(InvalidLinkMsgs.couldNotFindSlot(pod, typeName, slotName))
			slotSrc := podSrc[slot.loc.file]
			if (slotSrc == null)
				return InvalidLinks.add(InvalidLinkMsgs.couldNotFindSrcFile(pod, slot.loc.file))

			return true
		}
	}
	
	DocType type() {
		podApiDao[pod._id][typeName]
	}

	DocSlot slot() {
		type.slot(slotName)
	}

	override Str title() {
		"Src"
	}
	
	override Uri? baseUri() {
		uri := `api/${typeName}/src`
		if (slotName != null)
			uri = uri.parent + `${uri.name}#line${slot.loc.line}`
		return uri
	}

	override FandocUri? toParentUri() {
		toApiUri(typeName)
	}
	
	override Uri toClientUrl() {
		isCorePod 
			? `http://fantom.org/doc/${podName}/src-${typeName}.fan`
			: super.toClientUrl
	}
}

const class FandocDocUri : FandocUri {
	@Inject private const RepoPodDocsDao	podDocDao
					const Uri 				fileUri
					const Str? 				headingId
	
	new make(Str podName, Version? podVersion, Uri fileUri, Str? headingId, |This| in) : super(podName, podVersion, in) { 
		this.fileUri 	= fileUri
		this.headingId	= headingId
	}
	
	override FandocUri toLatest() {
		reg.autobuild(FandocDocUri#, [podName, null, fileUri, headingId])
	}

	Bool isAsset() {
		fileUri.ext != "fandoc"
	}
	
	FandocDocAsset toAsset() {
		reg.autobuild(FandocDocAsset#, [this])
	}
	
	Bool exists() {
		validate
	}
	
	Str docHtml() {
		fandoc := podDocDao[pod._id][fileUri].readAllStr
		return fandocRenderer.writeStrToHtml(fandoc, LinkResolverCtx(pod))
	}
	
	Uri:Str pageContents() {
		// TODO: look for a contents.fog
		pageUris := (Uri[]) podDocDao[pod._id].fandocPages.keys.exclude { it == `/doc/pod.fandoc`}.sort
		contents := Uri:Str[:] { it.ordered = true }.add(`/doc/pod.fandoc`, "User Guide")
		pageUris.each {
			contents[it] = it.name[0..<it.name.indexr(".")].toDisplayName
		}
		return contents
	}
	
	Buf? content() {
		podDocDao[pod._id]?.get(fileUri)
	}
	
	Heading[] findHeadings() {
		fandoc := podDocDao[pod._id][fileUri].readAllStr
		return fandocRenderer.parseStr(FandocParser(), fandoc).findHeadings
	}
	
	override Bool validate() {
		isCorePod ? true :
		validatePod |RepoPod pod->Bool?| {
			
			// validate Doc File
			podDoc := podDocDao.get(pod._id, false)
			if (podDoc == null)
				return InvalidLinks.add(InvalidLinkMsgs.couldNotFindDocFiles(pod))
			docFile := podDoc.get(fileUri, false)
			if (docFile == null)
				return InvalidLinks.add(InvalidLinkMsgs.couldNotFindDocFile(pod, fileUri))

			if (headingId == null)
				return true

			// validate Heading
			doc		:= fandocRenderer.parseStr(FandocParser(), docFile.readAllStr)
			heading	:= doc.findHeadings.find { (it.anchorId ?: it.title.fromDisplayName) == headingId }
			headings := doc.findHeadings.map {  it.anchorId ?: it.title.fromDisplayName }.sort.join(", ")
			if (heading == null)
				return InvalidLinks.add(InvalidLinkMsgs.couldNotFindHeading(headingId, headings))
			
			return true
		}
	}

	override Uri? baseUri() {
		fileUri := (Uri?) (fileUri == `/doc/pod.fandoc` ? null : fileUri)
		if (fileUri?.ext == "fandoc")
			fileUri = fileUri.plusName(fileUri.name[0..<fileUri.name.indexr(".")])
		uri := fileUri?.relTo(`/`) ?: `doc/`
		if (headingId != null)
			uri = `${uri}#${headingId}`
//			uri = uri.plusName("${uri.name}#line${slot.loc.line}")
		return uri
	}
	
	override Str title() {
		pageContents[fileUri] ?: "Page ${fileUri} does not exist"
	}
	
	override FandocUri? toParentUri() {
		toSummaryUri
	}
	
	override Uri toClientUrl() {
		if (!isCorePod)
			return super.toClientUrl
		
		if (fileUri == `/doc/pod.fandoc`)
			return `http://fantom.org/doc/${podName}/index.html`
		
		fileStr := fileUri.relTo(`/doc/`).toStr.replace(".fandoc", "").toUri
		if (fileStr.ext == null)
			fileStr = `${fileStr}.html`
		return headingId == null
			? `http://fantom.org/doc/${podName}/` + fileStr
			: `http://fantom.org/doc/${podName}/` + `${fileStr}#${headingId}`
	}
}
