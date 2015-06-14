
const class ArticleLinkResolver : LinkResolver {
	
	override Uri? resolve(Str uri, LinkResolverCtx ctx) {
		"article".split.contains(uri.toUri.scheme ?: "") ? `http://www.fantomfactory.org/articles/` + uri.toUri.pathOnly : null
	}
	
}
