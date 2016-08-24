using afIoc

internal const class PodLinkResolver : LinkResolver {

	@Inject private const Scope	scope
	
	new make(|This|in) { in(this) }
	
	override Uri? resolve(Str str, LinkResolverCtx ctx) {
		uri := str.toUri
		if (uri.scheme != "pod") return null

		fandocUri := FandocUri.fromUri(scope, `fandoc:/${uri.pathStr}`)
		if (fandocUri == null)
			return null
		
		if (fandocUri.validate == false)
			return null
		
		return fandocUri.toClientUrl
	}
}
