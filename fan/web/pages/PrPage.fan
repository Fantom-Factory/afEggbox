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
	
	Str podSummaryUrl(RepoPod pod) {
		pages[PodsPage#].pageUrl.plusSlash.plusName(pod.name).encode
	}
}
