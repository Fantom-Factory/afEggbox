
** (Service) - 
@NoDoc	// don't overwhelm the masses
internal class LinkResolvers {
	private const LinkResolver[] 	resolvers

	new make(LinkResolver[] resolvers, |This|in) { 
		in(this) 
		this.resolvers = resolvers
	}
	
	Uri? resolve(Uri uri, LinkResolverCtx? ctx := null) {
		resolvers.eachWhile { it.resolve(uri, ctx ?: LinkResolverCtx()) } ?: throw Err("Could not resolve link - $uri")
	}
}