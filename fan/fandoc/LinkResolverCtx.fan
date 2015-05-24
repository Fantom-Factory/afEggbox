using fandoc

class LinkResolverCtx {
	Uri:Str		invalidLinks	:= Uri:Str[:] { ordered = true }
	RepoPod?	pod
	Str?		type
	Doc?		doc
	
	new make() { }
	
	new makeWithPod(RepoPod pod) { 
		this.pod = pod 
	}
	
	Uri? invalidLink(Uri uri, Str msg, Uri? returnUri := null) {
		invalidLinks[uri] = msg
		return returnUri
	}
	
	Obj? withPod(RepoPod pod, |LinkResolverCtx->Obj?| func) {
		origPod := this.pod
		try {
			this.pod = pod
			return func(this)
		} finally {
			this.pod = origPod
		}
	}

	Obj? withDoc(Doc doc, |LinkResolverCtx->Obj?| func) {
		origDoc := this.doc
		try {
			this.doc = doc
			return func(this)
		} finally {
			this.doc = origDoc
		}
	}
}