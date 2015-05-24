using afIoc
using afBedSheet
using afPillow
using fandoc

** Supports Fantom links as defined in `compilerDoc::DocLink`:
**
**    Format             Display     Links To
**    ------             -------     --------
**    pod::index         pod         absolute link to pod index
**    pod::pod-doc       pod         absolute link to pod doc chapter
**    pod::Type          Type        absolute link to type qname
**    pod::Types.slot    Type.slot   absolute link to slot qname
**    pod::Chapter       Chapter     absolute link to book chapter
**    pod::Chapter#frag  Chapter     absolute link to book chapter anchor
**    Type               Type        pod relative link to type
**    Type.slot          Type.slot   pod relative link to slot
**    slot               slot        type relative link to slot
**    Chapter            Chapter     pod relative link to book chapter
**    Chapter#frag       Chapter     pod relative link to chapter anchor
**    #frag              heading     chapter relative link to anchor		--> see AnchorLinkResolver
**
@NoDoc
public const class FantomLinkResolver : LinkResolver {

	@Inject private const Registry			reg

	new make(|This|in) { in(this) }
	
	** Link to Fantom Types - Damn you Fantom for creating this crappy syntax!
	override Uri? resolve(Str str, LinkResolverCtx ctx) {
		uri := str.toUri

		fandocUri := FandocUri.fromFantomUri(reg, ctx, str)
		if (fandocUri == null)
			return null
		
		if (fandocUri.validate(ctx, uri) == false)
			return null
		
		return fandocUri.toClientUrl
	}	
}
