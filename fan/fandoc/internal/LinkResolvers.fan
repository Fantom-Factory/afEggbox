
** (Service) - 
@NoDoc	// don't overwhelm the masses
internal class LinkResolvers {
	private const LinkResolver[] 	resolvers

	new make(LinkResolver[] resolvers, |This|in) { 
		in(this) 
		this.resolvers = resolvers
	}
	
	Uri? resolve(Str url, LinkResolverCtx? ctx := null) {
		resolvers.eachWhile { it.resolve(url, ctx ?: LinkResolverCtx()) } ?: throw Err("Could not resolve link - $url")
	}
}