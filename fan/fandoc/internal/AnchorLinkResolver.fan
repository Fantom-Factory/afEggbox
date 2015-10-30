using afBeanUtils

internal const class AnchorLinkResolver : LinkResolver {
	
	** Validate in-page anchors
	override Uri? resolve(Str str, LinkResolverCtx ctx) {
		uri := str.toUri
		if (str.startsWith("#") && ctx.doc != null) {
			id := uri.toStr[1..-1]
			hd := ctx.doc.findHeadings.find { (it.anchorId ?: Utils.fromDisplayName(it.title)) == id }
			if (hd == null) {
				headings := ctx.doc.findHeadings.map { it.anchorId ?: Utils.fromDisplayName(it.title) }.sort.join(", ")
				return InvalidLinks.add(InvalidLinkMsgs.couldNotFindHeading(uri.frag, headings))
			}
			return uri
		}
		return null
	}
}
