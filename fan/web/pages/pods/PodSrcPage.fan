using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using syntax
using web

@Page { disableRouting = true }
const mixin PodSrcPage : PrPage {

	@PageContext	abstract FandocSrcUri	fandocUri

	RepoPod pod() {
		fandocUri.pod
	}
	
	override Bool isPublic() { pod.isPublic	}
}
