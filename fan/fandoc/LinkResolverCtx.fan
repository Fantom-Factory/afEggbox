using fandoc

class LinkResolverCtx {
	Str:Str		invalidLinks	:= Str:Str[:] { ordered = true }
	RepoPod?	pod
	Doc?		doc
	
//	new make(|This|in) { in(this) }
	
	Uri? invalidLink(Str url, Str msg) {
		invalidLinks[url] = msg
		return null
	}
}