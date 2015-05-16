using afIoc
using afBedSheet
using afPillow
using fandoc

internal const class FandocLinkResolver : LinkResolver {

	@Inject private const Pages				pages
	@Inject private const RepoPodDao		podDao
	@Inject private const RepoPodApiDao		podApiDao
	@Inject private const RepoPodDocsDao	podDocDao
	@Inject private const RepoPodSrcDao		podSrcDao
	
	new make(|This|in) { in(this) }
	
	override Uri? resolve(Uri uri, LinkResolverCtx ctx) {
		if (uri.scheme != "fandoc" || uri.auth != null || uri.path.isEmpty)
			return null
		
		path 		:= normalise(uri).path
		podName		:= chomp(path)
		podVersion	:= Version(uri.query["v"], false)
		pod			:= podDao.findOne(podName, podVersion)
		latestPod	:= podDao.findOne(podName)
		isLatest	:= pod.version == latestPod.version
		
		if (pod == null)
			return ctx.invalidLink(uri, "Could not find pod ${podName}" + (podVersion == null ? "" : " v${podVersion}"))

		if (path.isEmpty)
			return summaryUrl(pod, isLatest)
		
		section		:= chomp(path).lower
		if (section == "api") {
			if (path.isEmpty)
				return summaryUrl(pod, isLatest).plusName("api", true)
			apiDocs := podApiDao.get(pod._id, false)
			if (apiDocs == null)
				return ctx.invalidLink(uri, "Could not find API documents for ${pod.name}")
			typeStr	:= chomp(path)
			apiKey	:= apiDocs.contents.keys.find { it.toStr.equalsIgnoreCase("/doc/${typeStr}.apidoc") }
			if (apiKey == null)
				return ctx.invalidLink(uri, "Could not find API document for `${pod.name}::${typeStr}`")
			apiType	:= ApiDocParser(apiDocs.contents[apiKey].in).parseType
			apiUri	:= summaryUrl(pod, isLatest).plusName("api", true).plusName(apiType.name)
			if (path.isEmpty && uri.frag == null)
				return apiUri
			slotStr	:= !path.isEmpty ? chomp(path) : uri.frag
			if (!path.isEmpty)
				return ctx.invalidLink(uri, "Invalid API URI, too many path segments", apiUri)
			slot	:= apiType.slot(slotStr, false)	// ApiDocParser ensures a case-insensitive match
			if (slot == null)
				return ctx.invalidLink(uri, "Could not find API slot for `${pod.name}::${apiType.name}.${slotStr}`", apiUri)
			return apiUri.plusName("${apiType.name}#${slot.name}")
		}

		if (section == "doc") {
			if (path.isEmpty)
				return summaryUrl(pod, isLatest).plusName("doc", true)
			podDocs := podDocDao.get(pod._id, false)
			if (podDocs == null)
				return ctx.invalidLink(uri, "Could not find documents for ${pod.name}")
			docUri	:= (Uri) path.reduce(`/doc/`) |Uri docUri, seg| { docUri.plusSlash.plusName(seg) }
			docKey	:= podDocs.contents.keys.find { it.toStr.equalsIgnoreCase(docUri.toStr) }
			if (docKey == null)
				return ctx.invalidLink(uri, "Could not find document ${docKey} for ${pod.name}")
			docUrl	:= summaryUrl(pod, isLatest) + docKey.relTo(`/`)
			if (uri.frag == null)
				return docUrl
			if (docKey.ext.lower == "fandoc" || docKey.ext.lower == "fan")
				try {
					fandoc	:= FandocParser().parseStr(podDocs.contents[docKey].readAllStr)
					heading	:= fandoc.findHeadings.find { (it.anchorId ?: it.title.fromDisplayName).equalsIgnoreCase(uri.frag) }
					if (heading == null)
						return ctx.invalidLink(uri, "Document ${docKey} in ${pod.name} does not contain a heading ID #${uri.frag}", docUrl)
					return docUrl.plusName("${docUrl.name}#${heading.anchorId ?: heading.title.fromDisplayName}")				
				} catch (Err err) {
					return ctx.invalidLink(uri, "Document ${docKey} in ${pod.name} is not a valid Fandoc - ${err.msg}", docUrl)
				}
			return docUrl
		}

		if (section == "src") {
			if (path.isEmpty)
//				return summaryUrl(pod, isLatest).plusName("src", true)
				return ctx.invalidLink(uri, "Invalid src URI")	// we don't yet have a src index page
			podSrc := podSrcDao.get(pod._id, false)
			if (podSrc == null)
				return ctx.invalidLink(uri, "Could not find src documents for ${pod.name}")
			typeStr	:= chomp(path)
			srcKey	:= podSrc.contents.keys.find { it.toStr.equalsIgnoreCase("/src/${typeStr}.fan") }
			if (srcKey == null)
				return ctx.invalidLink(uri, "Could not find src document for `${pod.name}::${typeStr}`")
			srcUri	:= summaryUrl(pod, isLatest).plusName("src", true).plusName(srcKey.path[1])
			if (uri.frag == null)
				return srcUri 
			lineStr	:= uri.frag
			line	:= (lineStr.size > 4) ? lineStr[0..4] : lineStr[0..-1]
			lineNo	:= (lineStr.size > 4) ? lineStr[4..-1].toInt(10, false) : null
			if (line.lower != "line" || lineNo == null)
				return ctx.invalidLink(uri, "Invalid line number '${line}'", srcUri)
			return srcUri.plusName("${srcUri.name}#${uri.frag}")
		}
		
		return ctx.invalidLink(uri, "Invalid section '${section}' in fandoc URI `${uri}`. Valid sections are: api, doc, src")
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
	
	static Void main() {
		echo(`a/b/c?v=2`.plusName("dude"))
	}
}
