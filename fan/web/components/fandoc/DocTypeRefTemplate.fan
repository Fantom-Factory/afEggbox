using afIoc
using afEfanXtra
 
const mixin DocTypeRefTemplate : EfanComponent {

	@Inject	abstract LinkResolvers		linkResolvers
			abstract LinkResolverCtx	ctx
			abstract DocTypeRef			ref
			abstract Bool				full

	@InitRender
	Void init(LinkResolverCtx ctx, DocTypeRef ref, Bool full) {
		this.ctx	= ctx
		this.ref	= ref
		this.full	= full
	}
	
	Str resolveUri() {
		// TODO: resolve pod version to nearest matching
		linkResolvers.resolve(`fandoc:/${ref.pod}/api/${ref.name}`, ctx)?.encode ?: "/ERROR"
	}
}
