using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodApiIndexPage : PrPage {

	@PageContext	abstract FandocApiUri	fandocUri

	RepoPod pod() {
		fandocUri.pod
	}

}
