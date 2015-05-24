using afBeanUtils

internal const class AnchorLinkResolver : LinkResolver {
	
	** Validate in-page anchors
	override Uri? resolve(Str str, LinkResolverCtx ctx) {
		uri := str.toUri
		if (str.startsWith("#") && ctx.doc != null) {
			id := uri.toStr[1..-1]
			hd := ctx.doc.findHeadings.find { (it.anchorId ?: it.title.fromDisplayName) == id }
			if (hd == null) {
				headings := ctx.doc.findHeadings.map { it.anchorId ?: it.title.fromDisplayName }.sort.join(", ")
				return ctx.invalidLink(uri, "Could not find heading: $uri Available headings: ${headings}")
			}
			return uri
		}
		return null
	}
}
