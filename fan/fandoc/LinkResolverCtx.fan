using fandoc

class LinkResolverCtx {
	Uri:Str		invalidLinks	:= Uri:Str[:] { ordered = true }
	RepoPod?	pod
	Doc?		doc
	
//	new make(|This|in) { in(this) }
	
	Uri? invalidLink(Uri uri, Str msg, Uri? returnUri := null) {
		invalidLinks[uri] = msg
		return returnUri
	}
}