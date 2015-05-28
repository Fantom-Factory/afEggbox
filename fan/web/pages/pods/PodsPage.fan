using afIoc
using afEfanXtra
using afPillow

@Page { disableRouting = true }
const mixin PodsPage : PrPage {

	@Inject abstract Registry		registry
	@Inject abstract RepoPodDao		podDao
			abstract RepoPod[]		allPods

	@InitRender
	Void initRender() {
		allPods = podDao.findPublic(userSession.user)
		injector.injectRequireModule("fileInput")
	}
	
	Str podSummaryUrl(RepoPod pod) {
		fandocUri(pod).toSummaryUri.toClientUrl.encode
	}

	Str podDocsHtml(RepoPod pod) {
		apiUri := fandocUri(pod).toApiUri
		docUri := fandocUri(pod).toDocUri
		if (apiUri.hasApi && docUri.hasDoc)
			return "<a href=\"${apiUri.toClientUrl.encode}\">API</a> / <a href=\"${docUri.toClientUrl.encode}\">User Guide</a>" 
		if (apiUri.hasApi)
			return "<a href=\"${apiUri.toClientUrl.encode}\">API</a>" 
		if (docUri.hasDoc)
			return "<a href=\"${docUri.toClientUrl.encode}\">User Guide</a>"
		return ""
	}
	
	Str userUrl(RepoUser user) {
		pages[UsersPage#].withContext([user]).pageUrl.encode
	}

	private FandocUri fandocUri(RepoPod pod) {
		registry.autobuild(FandocSummaryUri#, [pod.name, pod.version])
	}
}
