using afIoc
using afEfanXtra
 
const mixin DocTypeRefTemplate : EfanComponent {

	@Inject 	abstract Registry			reg
	@Autobuild	abstract FantomLinkResolver	fantomLinkResolver
				abstract DocTypeRef			ref
				abstract Bool				full

				abstract LinkResolverCtx ctx
				abstract Str				typeUrl

	@InitRender
	Void init(LinkResolverCtx ctx, DocTypeRef ref, Bool full) {
		this.ctx	= ctx
		this.ref	= ref
		this.full	= full
	}
	
	Bool resolved() {
		// TODO: resolve pod version to nearest matching
		// TODO: need to know which version of the pod we're linking from

		uri		  := `fandoc:/${ref.pod}/api/${ref.name}`
		fandocUri := FandocUri.fromUri(reg, ctx, uri)
//		fandocUri := (FandocUri) reg.autobuild(FandocUri#, [LinkResolverCtx(), `fandoc:/${ref.pod}/api/${ref.name}`])
		if (fandocUri.validate(ctx, uri)) {
			typeUrl = fandocUri.toClientUrl.encode
			return true
		}
		
//		if (isSysPod(ref.pod)) {
//			typeUrl = `http://fantom.org/doc/${ref.pod}/${ref.name}.html`.encode
//			return true
//		}
		
		return false
	}
	
//	Bool isSysPod(Str podName) {
//		sysPodNames.contains(podName.lower)
//	}
}
