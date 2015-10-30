using afIoc
using afEfanXtra
 
const mixin DocFacetTemplate : EfanComponent { 

	abstract LinkResolverCtx	ctx
	abstract DocFacet			ref

	@InitRender
	Void init(LinkResolverCtx ctx, DocFacet ref) {
		this.ctx	= ctx
		this.ref	= ref
	}
}
