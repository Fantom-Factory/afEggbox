using afIoc::Inject
using afBedSheet
using afEfanXtra
using afPillow
using afDuvet

@Abstract @Page
const mixin PrPage : PrComponent {

	Bool isActive() {
		this.typeof.fits(pageMeta.pageType) 
	}
}
