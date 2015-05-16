using afIoc
using afBedSheet
using afPillow

internal const class FandocLinkResolver : LinkResolver {

	@Inject private const RepoPodDao		podDao
	@Inject private const Pages				pages
	@Inject private const RepoPodApiDao		podApiDao
	@Inject private const RepoPodDocsDao	podDocDao
	@Inject private const RepoPodSrcDao		podSrcDao
	
	new make(|This|in) { in(this) }
	
	override Uri? resolve(Str url, LinkResolverCtx ctx) {
		uri := url.toUri
		if (uri.scheme != "fandoc" || uri.auth != null || uri.path.isEmpty)
			return null
		
		path 		:= normalise(uri).path
		podName		:= chomp(path)
		podVersion	:= Version(uri.query["v"], false)
		pod			:= podDao.findOne(podName, podVersion)
		latestPod	:= podDao.findOne(podName)
		isLatest	:= pod.version == latestPod.version
		
		if (pod == null)
			return ctx.invalidLink(url, "Could not find pod ${podName}" + (podVersion == null ? "" : " v${podVersion}"))

		if (path.isEmpty)
			return summaryUrl(pod, isLatest)
		
		section		:= chomp(path).lower
		if (section == "api") {
			if (path.isEmpty)
				return summaryUrl(pod, isLatest).plusName("api", true)
			apiDocs := podApiDao.get(pod._id)
			typeStr	:= chomp(path)
			apiKey	:= apiDocs.contents.keys.find { it.toStr.equalsIgnoreCase("/doc/${typeStr}.apidoc") }
			if (apiKey == null)
				return ctx.invalidLink(url, "Could not find API document for `${pod.name}::${typeStr}`")
			docType	:= ApiDocParser(apiDocs.contents[apiKey].in).parseType
			if (path.isEmpty && uri.frag == null)
				return summaryUrl(pod, isLatest).plusName("api", true).plusName(docType.name)
			slotStr	:= !path.isEmpty ? chomp(path) : uri.frag
			if (!path.isEmpty)
				return ctx.invalidLink(url, "Invalid API URI, too many path segments")
			slot	:= docType.slot(slotStr, false)	// ApiDocParser ensures a case-insensitive match
			if (slot == null)
				return ctx.invalidLink(url, "Could not find API slot for `${pod.name}::${docType.name}.${slotStr}`")
			return summaryUrl(pod, isLatest).plusName("api", true).plusName("${docType.name}#${slot.name}")
		}

		if (section == "doc") {
			if (path.isEmpty)
				return summaryUrl(pod, isLatest).plusName("doc", true)
			podDocs := podDocDao.get(pod._id)
			docUri	:= (Uri) path.reduce(`/doc/`) |Uri docUri, seg| { docUri.plusSlash.plusName(seg) }
			docKey	:= podDocs.contents.keys.find { it.toStr.equalsIgnoreCase(docUri.toStr) }
			if (docKey == null)
				return ctx.invalidLink(url, "Could not find document ${docKey} for ${pod.name}")
			docUrl	:= summaryUrl(pod, isLatest) + docKey.relTo(`/`)
			if (uri.frag == null)
				return docUrl
			return docUrl.plusName("${docUrl.name}#${uri.frag}")
		}

		if (section == "src") {
			if (path.isEmpty)
//				return summaryUrl(pod, isLatest).plusName("src", true)
				return ctx.invalidLink(url, "Invalid src URI")	// we don't yet have a src index page
			podSrc := podSrcDao.get(pod._id)
			typeStr	:= chomp(path)
			srcKey	:= podSrc.contents.keys.find { it.toStr.equalsIgnoreCase("/src/${typeStr}.fan") }
			if (srcKey == null)
				return ctx.invalidLink(url, "Could not find src document for `${pod.name}::${typeStr}`")
			if (uri.frag == null)
				return summaryUrl(pod, isLatest).plusName("src", true).plusName(srcKey.path[1])
			lineStr	:= uri.frag
			line	:= (lineStr.size > 4) ? lineStr[0..4] : lineStr[0..-1]
			lineNo	:= (lineStr.size > 4) ? lineStr[4..-1].toInt(10, false) : null
			if (line.lower != "line" || lineNo == null)
				return ctx.invalidLink(url, "Invalid line number '${line}'")
			return summaryUrl(pod, isLatest).plusName("src", true).plusName(srcKey.name)			
		}
		
		return ctx.invalidLink(url, "Invalid section '${section}' in fandoc URI `${url}`. Valid sections are: api, doc, src")
	}
	
	private Uri summaryUrl(RepoPod pod, Bool isLatest) {
		url := pages[PodsPage#].pageUrl
		url = url.plusSlash.plusName(pod.name).plusSlash
		if (!isLatest)
			url = url.plusName(pod.version.toStr).plusSlash
		return url
	}
	
	** Tidy up fandoc URIs 
	private Uri normalise(Uri uri) {
		// ensure URI is absolute, `fandoc:afFancom` to `fandoc:/afFancom`
		if (!uri.isPathAbs)
			uri = `fandoc:/` + uri

		// expand 'fandoc:/afFancom' to 'fandoc:/afFancom/' 
		if (uri.path.size == 1)
			uri = uri.plusSlash
		
		return uri
	}
	
	private Str? chomp(Str[] path) {
		path.isEmpty ? null : path.removeAt(0) 
	}
}
