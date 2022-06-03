using afIoc
using afEfanXtra
 
const mixin DocTypeRefTemplate : EfanComponent {

	@Inject 	abstract Scope				scope
	@Autobuild	abstract FantomLinkResolver	fantomLinkResolver
				abstract DocTypeRef			ref
				abstract Bool				full

				abstract LinkResolverCtx	ctx
				abstract Str				typeUrl

	@InitRender
	Void init(LinkResolverCtx ctx, DocTypeRef ref, Bool full) {
		this.ctx	= ctx
		this.ref	= ref
		this.full	= full
	}
	
	Bool resolved() {
		// TODO resolve pod version to nearest matching
		
		fandocUri := (FandocApiUri) scope.build(FandocApiUri#, [ref.pod, null, ref.name, null]) 
		if (fandocUri.validate) {
			typeUrl = fandocUri.toClientUrl.encode
			return true
		}
		
		return false
	}
}
