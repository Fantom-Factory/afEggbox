using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using syntax
using web
using afGoogleAnalytics::GoogleAnalytics

@Page { disableRouting = true }
const mixin PodSrcPage : PrPage {

	@PageContext	abstract FandocSrcUri	fandocUri
	@Inject	abstract EggboxConfig			eggboxConfig
	@Inject	abstract GoogleAnalytics		googleAnalytics

	
	@BeforeRender
	Void beforeRender() {
		// redirect on dodgy name casing - this keeps GoogleAnalytics happy
		if (fandocUri.podName != pod.name)
			throw ReProcessErr(Redirect.movedTemporarily(pod.toSrcUri(fandocUri.typeName, fandocUri.slotName).toClientUrl))

		if (eggboxConfig.googleAnalyticsEnabled)
			googleAnalytics.sendPageView(fandocUri.toSummaryUri.toClientUrl)
	}

	RepoPod pod() {
		fandocUri.pod
	}
	
	Bool isPublic() {
		pod.isPublic
	}
}
