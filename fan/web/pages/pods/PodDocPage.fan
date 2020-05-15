using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using fandoc
using afGoogleAnalytics::GoogleAnalytics

@Page { disableRouting = true }
const mixin PodDocPage : PrPage {

	@PageContext	abstract FandocDocUri	fandocUri
	@Inject	abstract EggboxConfig			eggboxConfig
	@Inject	abstract GoogleAnalytics		googleAnalytics

	@BeforeRender
	Void beforeRender() {
		// redirect on dodgy name casing - this keeps GoogleAnalytics happy
		if (fandocUri.podName != pod.name)
			throw HttpRedirect.movedTemporarilyErr(pod.toDocUri(fandocUri.fileUri).toClientUrl)

		injector.injectRequireModule("anchorJS", null, [".fandoc h2, .fandoc h3, .fandoc h4"])

		if (eggboxConfig.googleAnalyticsEnabled)
			googleAnalytics.renderPageView(fandocUri.toSummaryUri.toClientUrl)
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
