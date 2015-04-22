using afIoc::Inject
using afBedSheet
using afEfanXtra
using afPillow
using afDuvet

@Abstract @Page
const mixin PrPage : PrComponent {

	@Inject	abstract PageMeta 		pageMeta
	
	Bool isActive() {
		this.typeof.fits(pageMeta.pageType) 
	}
}
