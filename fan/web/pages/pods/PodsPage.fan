using afIoc
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodsPage : PrPage {

	@Inject abstract Registry		registry
	@Inject abstract RepoPodDao		podDao
			abstract RepoPod[]		allPods

	@InitRender
	Void initRender() {
		allPods = podDao.findPublic(userSession.user)
		injector.injectRequireModule("rowLink")
	}
	
	Str podSummaryUrl(RepoPod pod) {
		fandocUri(pod).toSummaryUri.toClientUrl.encode
	}

	Str podDocsHtml(RepoPod pod) {
		apiUri := fandocUri(pod).toApiUri
		docUri := fandocUri(pod).toDocUri
		if (apiUri.exists && docUri.exists)
			return "<a href=\"${apiUri.toClientUrl.encode}\">API</a> / <a href=\"${docUri.toClientUrl.encode}\">User Guide</a>" 
		if (apiUri.exists)
			return "<a href=\"${apiUri.toClientUrl.encode}\">API</a>" 
		if (docUri.exists)
			return "<a href=\"${docUri.toClientUrl.encode}\">User Guide</a>"
		return ""
	}
	
	private FandocUri fandocUri(RepoPod pod) {
		registry.autobuild(FandocSummaryUri#, [pod.name, pod.version])
	}
}
