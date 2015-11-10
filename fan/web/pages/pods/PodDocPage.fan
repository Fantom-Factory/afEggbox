using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using fandoc

@Page { disableRouting = true }
const mixin PodDocPage : PrPage {

	@PageContext	abstract FandocDocUri	fandocUri
	@Inject	abstract EggboxConfig			eggboxConfig
	@Inject	abstract GoogleAnalytics		googleAnalytics

	@BeforeRender
	Void beforeRender() {
		if (fandocUri.toClientUrl != bedServer.toClientUrl(httpRequest.url) )
			throw ReProcessErr(Redirect.movedTemporarily(fandocUri.toClientUrl))
		injector.injectRequireModule("anchorJS", null, [".fandoc h2, .fandoc h3, .fandoc h4"])

		if (eggboxConfig.googleAnalyticsEnabled)
			googleAnalytics.sendPageView(fandocUri.toSummaryUri.toClientUrl)
	}

	RepoPod pod() {
		fandocUri.pod
	}

	Str docHtml() {
		fandocUri.docHtml
	}
	
	Str apiUrl() {
		fandocUri.toApiUri.toClientUrl.encode
	}
	
	Bool isPublic() {
		pod.isPublic
	}
}
