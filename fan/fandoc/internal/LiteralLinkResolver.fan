
const class LiteralLinkResolver : LinkResolver {
	
	override Uri? resolve(Uri uri, LinkResolverCtx ctx) {
		"http https ftp data".split.contains(uri.scheme) ? uri : null
	}
	
}
