using afIoc
using afBedSheet
using afFormBean
using afEfanXtra
using afPillow
using afSitemap

const mixin UsersPage : PrPage, SitemapSource {
	
	@Inject			abstract BedSheetServer	bedServer
	@Inject			abstract RepoUserDao	userDao
	@PageContext	abstract RepoUser		user
	
	override SitemapUrl[] sitemapUrls() {
		userDao.findAll.map |user| {
			SitemapUrl(bedServer.toAbsoluteUrl(Uri.decode(userUrl(user)))) {
				lastMod		= DateTime.boot
				changefreq	= SitemapFreq.yearly
				priority 	= 0.3f
			}
		}
	}
}
