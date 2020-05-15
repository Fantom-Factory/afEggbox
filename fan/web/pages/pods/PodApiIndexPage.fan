using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afGoogleAnalytics::GoogleAnalytics

@Page { disableRouting = true }
const mixin PodApiIndexPage : PrPage {

	@PageContext	abstract FandocApiUri	fandocUri
	@Inject	abstract EggboxConfig			eggboxConfig
	@Inject	abstract GoogleAnalytics		googleAnalytics

	@BeforeRender
	Void beforeRender() {
		// redirect on dodgy name casing - this keeps GoogleAnalytics happy
		if (fandocUri.podName != pod.name)
			throw HttpRedirect.movedTemporarilyErr(pod.toApiUri.toClientUrl)

		if (eggboxConfig.googleAnalyticsEnabled)
			googleAnalytics.renderPageView(fandocUri.toSummaryUri.toClientUrl)
	}

	RepoPod pod() {
		fandocUri.pod
	}

	Bool isPublic() {
		pod.isPublic
	}
}
