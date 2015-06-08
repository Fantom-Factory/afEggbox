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
	
	Int countPublicVersions() {
		podDao.countPublicVersions(null)
	}
	
	Str podSummaryUrl(RepoPod pod) {
		pod.toSummaryUri.toClientUrl.encode
	}

	Str podDocsHtml(RepoPod pod) {
		if (pod.hasApi && pod.hasDocs)
			return "<a href=\"${pod.toApiUri.toClientUrl.encode}\">API</a> / <a href=\"${pod.toDocUri.toClientUrl.encode}\">User Guide</a>" 
		if (pod.hasApi)
			return "<a href=\"${pod.toApiUri.toClientUrl.encode}\">API</a>" 
		if (pod.hasDocs)
			return "<a href=\"${pod.toDocUri.toClientUrl.encode}\">User Guide</a>"
		return ""
	}
	
	Str editUrl(RepoPod pod) {
		pod.toSummaryUri.toClientUrl.plusSlash.plusName("edit").encode
	}
}
