using afIoc
using afBedSheet
using afPillow
using fandoc

** Supports Fantom links as defined in `compilerDoc::DocLink`:
**
**    Format             Display     Links To
**    ------             -------     --------
**    pod::index         pod         absolute link to pod index
**    pod::pod-doc       pod         absolute link to pod doc chapter
**    pod::Type          Type        absolute link to type qname
**    pod::Types.slot    Type.slot   absolute link to slot qname
**    pod::Chapter       Chapter     absolute link to book chapter
**    pod::Chapter#frag  Chapter     absolute link to book chapter anchor
**    Type               Type        pod relative link to type
**    Type.slot          Type.slot   pod relative link to slot
**    slot               slot        type relative link to slot
**    Chapter            Chapter     pod relative link to book chapter
**    Chapter#frag       Chapter     pod relative link to chapter anchor
**    #frag              heading     chapter relative link to anchor		--> see AnchorLinkResolver
**
internal const class FantomLinkResolver : LinkResolver {

	@Inject private const Pages				pages
	@Inject private const RepoPodDao		podDao
	@Inject private const RepoPodApiDao		podApiDao
	@Inject private const RepoPodDocsDao	podDocDao
	@Inject private const RepoPodSrcDao		podSrcDao

	new make(|This|in) { in(this) }
	
	** Link to Fantom Types - Damn you Fantom for creating this crappy syntax!
	override Uri? resolve(Uri uri, LinkResolverCtx ctx) {
		link := uri.toStr
		
		if (link.contains("::")) {
			if (link.split(':').size > 3)
				return ctx.invalidLink(uri, "Invalid API URI, too many path segments")
			podName	:= link.split(':').first
			typeStr	:= link[podName.size+2..-1]
			pod		:= podDao.findOne(podName, null)
			if (pod == null)
				return ctx.invalidLink(uri, "Could not find pod ${podName}")
			return ctx.withPod(pod) {
				resolveFromPod(uri, typeStr, ctx)
			}
		}
		
		if (ctx.pod != null && uri.scheme == null && !uri.isPathAbs) {
			return resolveFromPod(uri, link, ctx)
			
			// FIXME: resolve type relative link to slot
		}
		
		// TODO: handle Fantom src URLs : adIoc::src-Inject.fan
		
		return null
	}
	
	private Uri summaryUrl(RepoPod pod) {
		url := pages[PodsPage#].pageUrl
		url = url.plusSlash.plusName(pod.name).plusSlash
		return url
	}
	
	Uri? resolveFromPod(Uri uri, Str? link, LinkResolverCtx ctx) {
		if (link.split('.').size > 2)
			return ctx.invalidLink(uri, "Invalid API URI, too many path segments")
		pod := ctx.pod
		if (link == null || link.isEmpty || link.equalsIgnoreCase("index"))
			return summaryUrl(pod)
		if (link.equalsIgnoreCase("pod-doc"))
			return summaryUrl(pod).plusName("doc", true)

		apiDocs := podApiDao.get(pod._id, false)
		if (apiDocs != null) {
			typeNom	:= link.split('.').first
			apiKey	:= apiDocs.contents.keys.find { it.toStr.equalsIgnoreCase("/doc/${typeNom}.apidoc") }
			if (apiKey != null) {
				docType	:= ApiDocParser(pod.name, apiDocs.contents[apiKey].in).parseType
				slotStr	:= link.split('.').getSafe(1)
				apiUri	:= summaryUrl(pod).plusName("api", true).plusName(docType.name)
				if (slotStr == null)
					return apiUri
				slot	:= docType.slot(slotStr, false)	// ApiDocParser ensures a case-insensitive match
				if (slot == null)
					return ctx.invalidLink(uri, "Could not find API slot for `${pod.name}::${docType.name}.${slotStr}`", apiUri)
				return apiUri.plusName("${docType.name}#${slot.name}")
			}
		}

		podDocs := podDocDao.get(pod._id, false)
		if (podDocs != null) {
			docNom	:= link.split('#').first
			docKey	:= podDocs.contents.keys.find { it.toStr.equalsIgnoreCase("/doc/${docNom}.fandoc") }
			if (docKey != null) {
				if (docNom.split('#').size > 2)
					return ctx.invalidLink(uri, "Invalid document URI, too many path fragments")
				docUrl	:= summaryUrl(pod) + docKey.relTo(`/`)
				fragStr	:= docNom.split('#').getSafe(1)
				if (fragStr == null)
					return docUrl					
				try {
					// FIXME: use Fandoc service
					fandoc	:= FandocParser().parseStr(podDocs.contents[docKey].readAllStr)
					heading	:= fandoc.findHeadings.find { (it.anchorId ?: it.title.fromDisplayName).equalsIgnoreCase(uri.frag) }
					if (heading == null)
						return ctx.invalidLink(uri, "Document ${docKey} in ${pod.name} does not contain a heading ID #${uri.frag}", docUrl)
					return docUrl.plusName("${docUrl.name}#${heading.anchorId ?: heading.title.fromDisplayName}")				
				} catch (Err err) {
					return ctx.invalidLink(uri, "Document ${docKey} in ${pod.name} is not a valid Fandoc - ${err.msg}", docUrl)
				}
			}
		}

		return null
	}
}
