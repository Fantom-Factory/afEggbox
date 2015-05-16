using afIoc
using afBedSheet

internal const class FantomLinkResolver : LinkResolver {

	@Inject private const BedSheetServer	bedServer
	@Inject private const RepoPodDocsDao	podDocDao
	
	new make(|This|in) { in(this) }
	
	** link to Fantom Types - Damn you Fantom for creating this crappy syntax!
	override Uri? resolve(Str url, LinkResolverCtx ctx) {
		
		return null
	}
}
