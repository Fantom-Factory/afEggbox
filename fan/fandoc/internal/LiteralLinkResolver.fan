
const class LiteralLinkResolver : LinkResolver {
	
	override Uri? resolve(Str uri, LinkResolverCtx ctx) {
		"http https ftp data".split.contains(uri.toUri.scheme ?: "") ? uri.toUri : null
	}
	
}
