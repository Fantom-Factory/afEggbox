using afIoc
using afBedSheet
using afSitemap

const class SitemapPages : SitemapSource {
	
	@Inject private const Registry			registry
	@Inject private const DirtyCash			dirtyCash
	@Inject private const BedSheetServer	bedServer
	@Inject private const RepoPodDao		podDao
	@Inject private const RepoPodDocsDao	podDocsDao
	@Inject private const RepoPodSrcDao		podSrcDao
	
	new make(|This|in) { in(this) }
	
	override SitemapUrl[] sitemapUrls() {
		dirtyCash.cash |->SitemapUrl[]| {
			urls := SitemapUrl[,]
			
			// only map the latest pod versions
			podDao.findPublic(null).each |pod| {
				// Pod Summary Page
				urls.add(SitemapUrl(bedServer.toAbsoluteUrl(pod.toSummaryUri.toClientUrl)) {
					lastMod		= pod.builtOn
					changefreq	= SitemapFreq.monthly
					priority 	= 0.9f
				})
		
				// Pod Document Pages
				if (pod.hasDocs) {
					podDocsDao[pod._id].fandocPages.keys.each |fileUri| {
						fandocDocUri := (FandocDocUri) registry.autobuild(FandocDocUri#, [pod.name, pod.version, fileUri, null])
						urls.add(SitemapUrl(bedServer.toAbsoluteUrl(fandocDocUri.toClientUrl)) {
							lastMod		= pod.builtOn
							changefreq	= SitemapFreq.monthly
							priority 	= 0.8f
						})
					}
				}
		
				// Pod API Pages
				if (pod.hasApi) {
					fandocApiUri := (FandocApiUri) registry.autobuild(FandocApiUri#, [pod.name, pod.version, null, null])
					urls.add(SitemapUrl(bedServer.toAbsoluteUrl(fandocApiUri.toClientUrl)) {
						lastMod		= pod.builtOn
						changefreq	= SitemapFreq.monthly
						priority 	= 0.8f
					})
					fandocApiUri.allTypes.each |apiUri| {
						urls.add(SitemapUrl(bedServer.toAbsoluteUrl(apiUri.toClientUrl)) {
							lastMod		= pod.builtOn
							changefreq	= SitemapFreq.monthly
							priority 	= 0.7f
						})
					}

					// Pod Src Pages - src pages are only mapped through API pages
					fandocApiUri.allTypes.map { it.toTypeSrcUri }.findAll { ((FandocSrcUri) it).hasSrc }.each |FandocSrcUri srcUri| { 
						urls.add(SitemapUrl(bedServer.toAbsoluteUrl(srcUri.toClientUrl)) {
							lastMod		= pod.builtOn
							changefreq	= SitemapFreq.monthly
							priority 	= 0.6f
						})				
					}
				}
			}
		
			return urls
		}
	}
}
