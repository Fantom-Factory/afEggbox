using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodSummaryPage : PrPage {

	@PageContext	abstract FandocSummaryUri	fandocUri
	
		// TODO: seo this page!
	
	RepoPod pod() {
		fandocUri.pod
	}

	Str aboutHtml() {
		fandocUri.aboutHtml
	}

	Str editUrl() {
		fandocUri.toClientUrl.plusSlash.plusName("edit").encode
	}

//	override Bool isPublic() { pod.isPublic	}
}
