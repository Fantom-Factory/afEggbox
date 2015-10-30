using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodApiIndexPage : PrPage {

	@PageContext	abstract FandocApiUri	fandocUri
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
