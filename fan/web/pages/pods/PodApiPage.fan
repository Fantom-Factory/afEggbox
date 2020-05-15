using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afGoogleAnalytics::GoogleAnalytics

@Page { disableRouting = true }
const mixin PodApiPage : PrPage {

	@PageContext	abstract FandocApiUri	fandocUri
	@Inject	abstract EggboxConfig			eggboxConfig
	@Inject	abstract GoogleAnalytics		googleAnalytics

	@BeforeRender
	Void beforeRender() {
		// redirect on dodgy name casing - this keeps GoogleAnalytics happy
		if (fandocUri.podName != pod.name)
			throw HttpRedirect.movedTemporarilyErr(pod.toApiUri(fandocUri.typeName, fandocUri.slotName).toClientUrl)

		if (eggboxConfig.googleAnalyticsEnabled)
			googleAnalytics.renderPageView(fandocUri.toSummaryUri.toClientUrl)
		
		injector.injectRequireModule("anchorJS", null, [".slots .id"])
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
