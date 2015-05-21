using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using syntax
using web

@Page { disableRoutes = true }
const mixin PodSrcPage : PrPage {

	@PageContext	abstract FandocSrcUri	fandocUri

	RepoPod pod() {
		fandocUri.pod
	}
}
