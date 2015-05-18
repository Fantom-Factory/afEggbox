using afIoc::Inject
using afBedSheet
using afEfanXtra
using afPillow
using afDuvet

@Abstract @Page
const mixin PrPage : PrComponent {

	@Inject	abstract Alert			alert

	Bool isActive() {
		this.typeof.fits(pageMeta.pageType) 
	}
	
	Str podsUrl() {
		pages[PodsPage#].pageUrl.encode
	}
	Str podSummaryUrl(RepoPod pod) {
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
}
