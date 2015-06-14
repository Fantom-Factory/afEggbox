
** (Service) - 
@NoDoc	// don't overwhelm the masses
class LinkResolvers {
	private const LinkResolver[] 	resolvers

	new make(LinkResolver[] resolvers, |This|in) { 
		in(this) 
		this.resolvers = resolvers
	}
	
	Uri? resolve(Str uriStr, LinkResolverCtx ctx) {
		InvalidLinks.setLinkBeingResolved(uriStr)
		links := InvalidLinks.invalidLinks?.size

		try uriStr.toUri
		catch {
			InvalidLinks.add("Could not parse link as URI")
			return null
		}
		
		resolved := resolvers.eachWhile { it.resolve(uriStr, ctx) }
		if (resolved == null && InvalidLinks.invalidLinks?.size == links)
			InvalidLinks.add("Could not resolve link")
		return resolved
	}
}