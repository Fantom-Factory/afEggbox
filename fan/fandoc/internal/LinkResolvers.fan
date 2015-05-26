
** (Service) - 
@NoDoc	// don't overwhelm the masses
class LinkResolvers {
	private const LinkResolver[] 	resolvers

	new make(LinkResolver[] resolvers, |This|in) { 
		in(this) 
		this.resolvers = resolvers
	}
	
	Uri? resolve(Str uri, LinkResolverCtx ctx) {
		InvalidLink.setLinkBeingResolved(uri)
		links := InvalidLink.invalidLinks?.size
		resolved := resolvers.eachWhile { it.resolve(uri, ctx) }
		if (resolved == null && InvalidLink.invalidLinks?.size == links)
			InvalidLink.invalidLink("Could not resolve link")
		return resolved
	}
}