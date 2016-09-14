using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afGoogleAnalytics::GoogleAnalytics

@Page { disableRouting = true }
const mixin PodsIndexPage : PrPage {

	@Inject abstract Registry			registry
	@Inject abstract RepoPodDao			podDao
	@Inject abstract HttpResponse		httpResponse
	@Inject	abstract EggboxConfig		eggboxConfig
	@Inject	abstract GoogleAnalytics	googleAnalytics
			abstract RepoPod[]			allPods
			abstract Int				countPublicPods
			abstract Bool				sortByName
			abstract Str[]				allTags

	@BeforeRender
	Void beforeRender() {
		if (httpRequest.url.isDir.not)
			throw ReProcessErr(Redirect.movedTemporarily(pages[PodsIndexPage#].pageUrl))
	}

	@InitRender
	Void initRender() {
		sortByName	= httpRequest.url.query.containsKey("sortByName")
		allPods	= podDao.findLatestPods.exclude { it.isDeprecated }
		if (sortByName)
			allPods = allPods.sort(RepoPodDao.byProjName)
		else
			allPods = allPods.sortr(RepoPodDao.byBuildDate)
		allTags = allPods.map { it.meta.tags }.flatten.unique.sort
		
		injector.injectRequireModule("podFiltering")
		
		// with all the params flying around on this page, ensure Google only indexes the main version
		// see https://support.google.com/webmasters/answer/139066
		canonicalUrl := bedServer.toAbsoluteUrl(pageMeta.pageUrl)
		httpResponse.headers["Link"] = "<${canonicalUrl.encode}>; rel=\"canonical\""
		injector.injectLink.fromExternalUrl(canonicalUrl).withRel("canonical")
		
		if (eggboxConfig.googleAnalyticsEnabled)
			googleAnalytics.renderPageView(pageMeta.pageUrl)
	}
	
	Str nameActive() {
		sortByName ? "active" : ""
	}
	
	Str dateActive() {
		sortByName ? "" : "active"
	}	
}
