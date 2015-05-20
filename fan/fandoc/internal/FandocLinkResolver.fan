using afIoc
using afBedSheet
using afPillow
using fandoc

internal const class FandocLinkResolver : LinkResolver {

	@Inject private const Registry			reg
	
	new make(|This|in) { in(this) }
	
	override Uri? resolve(Uri uri, LinkResolverCtx ctx) {
		if (uri.scheme != "fandoc") return null

		fandocUri := FandocUri(reg, ctx, uri)
		if (fandocUri == null)
			return null
		
		valid := fandocUri.validate(ctx, uri) ?: false
		if (!valid)
			return null
		
		return fandocUri.toClientUrl
	}
}








abstract const class FandocUri {
	@Inject private const RepoPodDao	podDao
					const Str 			podName
					const Version?		podVersion

	protected new make(Str podName, Version? podVersion, |This| in) {
		this.podName 	= podName
		this.podVersion	= podVersion
		in(this)
	}
	
	static new fromUri(Registry reg, LinkResolverCtx ctx, Uri uri) {
		if (uri.auth != null || uri.path.isEmpty)
			return null

		path 		:= uri.path.rw
		podName		:= chomp(path)
		podVersion	:= Version(uri.query["v"] ?: "", false)

		if (path.isEmpty)
			return reg.autobuild(FandocSummaryUri#, [podName, podVersion])

		section	:= chomp(path)
		if (section == "api") {
			typeName := chomp(path)
			if (!path.isEmpty)
				ctx.invalidLink(uri, "Too many path segments: ${path}")
			slotName := uri.frag
			return reg.autobuild(FandocApiUri#, [podName, podVersion, typeName, slotName])
		}

		if (section == "src") {
			typeName := chomp(path)
			if (!path.isEmpty)
				ctx.invalidLink(uri, "Too many path segments: ${path}")
			slotName := uri.frag
			return reg.autobuild(FandocSrcUri#, [podName, podVersion, typeName, slotName])
		}

		if (section == "doc") {
			docUri := uri.getRangeToPathAbs(1..-1).pathOnly
			if (docUri.isDir)
				docUri = docUri.plusName("pod.fandoc")
			if (docUri.ext == null)
				docUri = (docUri.toStr + ".fandoc").toUri
			headingId := uri.frag
			return reg.autobuild(FandocDocUri#, [podName, podVersion, docUri, headingId])
		}

		ctx.invalidLink(uri, "Invalid path segment '${section}'")
		return null
	}
	
	private static Str? chomp(Str[] path) {
		path.isEmpty ? null : path.removeAt(0) 
	}
	
	protected Uri fandocUri(Uri? uri) {
		uri == null
			? `fandoc:/${podName}`.plusQuery(["v":podVersion.toStr])
			: `fandoc:/${podName}/`.plus(uri).plusQuery(["v":podVersion.toStr])
	}
	
	protected Uri fandocUrl(Uri? url) {
		latestPod := podDao.findOne(podName)
		path := (podVersion == null || podVersion == latestPod.version) 
			? `/pods/${podName}` 
			: `/pods/${podName}/${podVersion}`
		return (url == null) ? path : path.plusSlash + url
	}
	
	protected Bool? validatePod(LinkResolverCtx ctx, Uri uri, |RepoPod->Bool?| func) {
		if (pod == null) {
			ctx.invalidLink(uri, "Could not find pod ${podName} " + (podVersion ?: ""))
			return false
		}
		return func(pod)
	}
	
	RepoPod? pod() {
		podDao.findOne(podName, podVersion)
	}
	
	abstract Bool? validate(LinkResolverCtx ctx, Uri uri)
	abstract Uri toUri()
	abstract Uri toClientUrl()
}

const class FandocSummaryUri : FandocUri {

	new make(Str podName, Version? podVersion, |This| in) : super(podName, podVersion, in) { }

	override Bool? validate(LinkResolverCtx ctx, Uri uri) {
		validatePod(ctx, uri) |pod->Bool?| { true }
	}
	
	override Uri toUri() {
		fandocUri(null)
	}

	override Uri toClientUrl() {
		fandocUrl(null)
	}
}

const class FandocApiUri : FandocUri {
	@Inject private const RepoPodApiDao	podApiDao
					const Str? 			typeName
					const Str? 			slotName

	new makeFromPod(RepoPod pod, Uri? fileUri, Str? typeName, Str? slotName, |This| in) : super.make(pod.name, pod.version, in) { 
		this.typeName 	= typeName
		this.slotName	= slotName
	}

	new make(Str podName, Version? podVersion, Str? typeName, Str? slotName, |This| in) : super(podName, podVersion, in) { 
		this.typeName = typeName
		this.slotName = slotName
	}
	
	override Bool? validate(LinkResolverCtx ctx, Uri uri) {
		validatePod(ctx, uri) |RepoPod pod->Bool?| {
			if (typeName == null)
				return true

			// validate Type
			podApi := podApiDao.get(pod._id, false)
			if (podApi == null)
				return (Obj?) ctx.invalidLink(uri, "Pod ${pod} has no API files")
			apiFile := podApi[typeName]
			if (apiFile == null)
				return (Obj?) ctx.invalidLink(uri, "Pod ${pod} does not have an API file for ${typeName}")

			if (slotName == null)
				return true
			
			// validate Slot
			type := ApiDocParser(pod.name, apiFile.in).parseType
			slot := type.slot(slotName, false)
			if (slot == null)
				// return true because the URL is still usable
				ctx.invalidLink(uri, "Type ${podName}::${typeName} does not have a slot named: ${slotName}")

			return true
		}
	}
	
	override Uri toUri() {
		uri := `api`
		if (typeName != null)
			uri = uri.plusSlash.plusName(typeName)
		if (slotName != null)
			uri = `${uri}#${slotName}`
		return fandocUri(uri)
	}

	override Uri toClientUrl() {
		url := `api`
		if (typeName != null)
			url = url.plusSlash.plusName(typeName)
		if (slotName != null)
			url = `${url}#${slotName}`
		return fandocUrl(url)
	}
}

const class FandocSrcUri : FandocUri {
	@Inject private const RepoPodApiDao	podApiDao
	@Inject private const RepoPodSrcDao	podSrcDao
					const Str? 			typeName
					const Str? 			slotName

	new make(Str podName, Version? podVersion, Str? typeName, Str? slotName, |This| in) : super(podName, podVersion, in) { 
		this.typeName = typeName
		this.slotName = slotName
	}
	
	override Bool? validate(LinkResolverCtx ctx, Uri uri) {
		validatePod(ctx, uri) |RepoPod pod->Bool?| {
			if (typeName == null)
				return true

			// validate Type
			podApi := podApiDao.get(pod._id, false)
			if (podApi == null)
				return (Obj?) ctx.invalidLink(uri, "Pod ${pod} has no API files")
			apiFile := podApi[typeName]
			if (apiFile == null)
				return (Obj?) ctx.invalidLink(uri, "Pod ${pod} does not have an API file for ${typeName}")
			type := ApiDocParser(pod.name, apiFile.in).parseType
			podSrc := podSrcDao.get(pod._id, false)
				return (Obj?) ctx.invalidLink(uri, "Pod ${pod} has no Src files")
			typeSrc := podSrc[type.loc.file]
			if (typeSrc == null)
				return (Obj?) ctx.invalidLink(uri, "Pod ${pod} does not have an Src file for ${type.loc.file}")
			
			if (slotName == null)
				return true
			
			// validate Slot
			slot := type.slot(slotName, false)
			if (slot == null)
				// return true because the URL is still usable
				ctx.invalidLink(uri, "Type ${podName}::${typeName} does not have a slot named: ${slotName}")
			slotSrc := podSrc[slot.loc.file]
			if (slotSrc == null)
				return (Obj?) ctx.invalidLink(uri, "Pod ${pod} does not have an Src file for ${slot.loc.file}")

			return true
		}
	}
	override Uri toUri() {
		uri := `src`
		if (typeName != null)
			uri = uri.plusSlash.plusName(typeName)
		if (slotName != null)
			uri = `${uri}#${slotName}`
		return fandocUri(uri)
	}
	
	override Uri toClientUrl() {
		url := `src`
		if (typeName != null)
			url = url.plusSlash.plusName(typeName)
		if (slotName != null)
			url = `${url}#${slotName}`
		return fandocUrl(url)
	}
}

const class FandocDocUri : FandocUri {
	@Inject private const RepoPodDocsDao	podDocDao
					const Uri? 				fileUri
					const Str? 				headingId

	new makeFromPod(RepoPod pod, Uri? fileUri, Str? headingId, |This| in) : super.make(pod.name, pod.version, in) { 
		this.fileUri 	= fileUri
		this.headingId	= headingId
	}
	
	new make(Str podName, Version? podVersion, Uri? fileUri, Str? headingId, |This| in) : super(podName, podVersion, in) { 
		this.fileUri 	= fileUri
		this.headingId	= headingId
	}
	
	Heading[] findHeadings() {
		podDocDao.get(pod._id).findHeadings(fileUri)
	}
	
	override Bool? validate(LinkResolverCtx ctx, Uri uri) {
		validatePod(ctx, uri) |RepoPod pod->Bool?| {
			if (fileUri == null)
				return true
			
			// validate Doc File
			podDoc := podDocDao.get(pod._id, false)
			if (podDoc == null)
				return (Obj?) ctx.invalidLink(uri, "Pod ${pod} has no Doc files")
			docFile := podDoc[fileUri]
			if (docFile == null)
				return (Obj?) ctx.invalidLink(uri, "Pod ${pod} does not have a Doc file `${fileUri}`")
			
			if (headingId == null)
				return true
			
			// validate Heading
			heading	:= podDoc.resolveHeading(fileUri, headingId)
			if (heading == null)
				return (Obj?) ctx.invalidLink(uri, "Document ${podName}${fileUri} does not contain the heading ID #${uri.frag}")
			
			return true
		}
	}

	Uri baseUri() {
		fileUri := (Uri?) (fileUri == `/doc/pod.fandoc` ? null : fileUri)
		if (fileUri?.ext == "fandoc")
			fileUri = fileUri.plusName(fileUri.name[0..<fileUri.name.indexr(".")])
		uri := fileUri?.relTo(`/`) ?: `doc`
		if (headingId != null)
			uri = `${uri}#${headingId}`
		return uri
	}
	
	override Uri toUri() {
		fandocUri(baseUri)
	}
	
	override Uri toClientUrl() {
		fandocUrl(baseUri)
	}
}
