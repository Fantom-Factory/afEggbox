using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using syntax
using web

@Page { disableRoutes = true }
const mixin PodSrcPage : PrPage {

	@PageContext	abstract FandocSrcUri	fandocUri
	@Inject	abstract EggboxConfig			eggboxConfig
	@Inject	abstract GoogleAnalytics		googleAnalytics

	
	@BeforeRender
	Void beforeRender() {
		if (fandocUri.toClientUrl != bedServer.toClientUrl(httpRequest.url) )
			throw ReProcessErr(Redirect.movedTemporarily(fandocUri.toClientUrl))

		if (eggboxConfig.googleAnalyticsEnabled)
			googleAnalytics.sendPageView(fandocUri.toSummaryUri.toUri)
	}

	RepoPod pod() {
		fandocUri.pod
	}
	
	Bool isPublic() {
		pod.isPublic
	}
}
