
const class LiteralLinkResolver : LinkResolver {
	
	override Uri? resolve(Str url, LinkResolverCtx ctx) {
		"http https ftp data".split.contains(url.toUri.scheme) ? url.toUri : null
	}
	
}
