using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRouting = true }
const mixin PodApiPage : PrPage {

	@PageContext	abstract FandocApiUri	fandocUri
	@Inject	abstract EggboxConfig			eggboxConfig
	@Inject	abstract GoogleAnalytics		googleAnalytics

	@BeforeRender
	Void beforeRender() {
		if (fandocUri.toClientUrl != bedServer.toClientUrl(httpRequest.url) )
			throw ReProcessErr(Redirect.movedTemporarily(fandocUri.toClientUrl))

		if (eggboxConfig.googleAnalyticsEnabled)
			googleAnalytics.sendPageView(fandocUri.toSummaryUri.toClientUrl)
	}

	RepoPod pod() {
		fandocUri.pod
	}

	DocType type() {
		fandocUri.type
	}
	
	LinkResolverCtx ctx() {
		LinkResolverCtx(pod) { it.type = fandocUri.typeName }
	}
	
	Bool isPublic() {
		pod.isPublic
	}
}
