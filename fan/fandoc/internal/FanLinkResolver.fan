using afIoc

internal const class FanLinkResolver : LinkResolver {

	@Inject private const Registry	reg
	
	new make(|This|in) { in(this) }
	
	override Uri? resolve(Str str, LinkResolverCtx ctx) {
		uri := str.toUri
		if (uri.scheme != "fan") return null

		podName := uri.host
		if (podName != null && uri.path.first != "doc")
			return InvalidLinks.add(InvalidLinkMsgs.fanSchemeDocDirOnly)

		fandocUri := FandocUri.fromUri(reg, `fandoc:/${podName}/` + uri.pathOnly.relTo(`/`))
		if (fandocUri == null)
			return null
		
		if (fandocUri.validate == false)
			return null
		
		if (fandocUri is FandocDocUri && ((FandocDocUri) fandocUri).isAsset)
			return ((FandocDocUri) fandocUri).toAsset.clientUrl
		
		return fandocUri.toClientUrl
	}
}
