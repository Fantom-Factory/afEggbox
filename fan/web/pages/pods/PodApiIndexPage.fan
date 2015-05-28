using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRouting = true }
const mixin PodApiIndexPage : PrPage {

	@PageContext	abstract FandocApiUri	fandocUri

	RepoPod pod() {
		fandocUri.pod
	}

	override Bool isPublic() { pod.isPublic	}

}
