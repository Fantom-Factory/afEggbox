using afBeanUtils

internal const class AnchorLinkResolver : LinkResolver {
	
	** Validate in-page anchors
	override Uri? resolve(Str url, LinkResolverCtx ctx) {
		if (url.startsWith("#") && ctx.doc != null) {
			id := url[1..-1]
			hd := ctx.doc.findHeadings.find { (it.anchorId ?: it.title.fromDisplayName) == id }
			if (hd == null) {
				headings := ctx.doc.findHeadings.map { it.anchorId ?: it.title.fromDisplayName }.sort.join(", ")
				return ctx.invalidLink(url, "Could not find heading: $url Available headings: ${headings}")
			}
			return url.toUri
		}
		return null
	}
}
