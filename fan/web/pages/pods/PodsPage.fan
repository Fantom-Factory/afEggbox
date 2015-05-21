using afIoc
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodsPage : PrPage {

	@Inject abstract RepoPodDao		podDao
			abstract RepoPod[]		allPods

	@InitRender
	Void initRender() {
		allPods = podDao.findPublic(userSession.user)
		injector.injectRequireModule("fileInput")
	}
	
	Str podSummaryUrl(RepoPod pod) {
		// FIXME: use FandocUri
		pages[PodsPage#].pageUrl.plusSlash.plusName(pod.name).encode
	}
	Str podApiUrl(RepoPod pod) {
		pages[PodsPage#].pageUrl.plusSlash.plusName(pod.name, true).plusName("api", true).encode
	}
	Str podDocsUrl(RepoPod pod) {
		pages[PodsPage#].pageUrl.plusSlash.plusName(pod.name, true).plusName("doc", true).encode
	}
	Str userUrl(RepoUser user) {
		pages[UsersPage#].withContext([user]).pageUrl.encode
	}
	Str downloads(Obj o) {
		""
	}
}
