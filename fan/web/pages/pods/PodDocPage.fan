using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using fandoc

@Page { disableRouting = true }
const mixin PodDocPage : PrPage {

	@PageContext	abstract FandocDocUri		fandocUri

	RepoPod pod() {
		fandocUri.pod
	}

	Str docHtml() {
		fandocUri.docHtml
	}
	
	Str apiUrl() {
		fandocUri.toApiUri.toClientUrl.encode
	}
	
	override Bool isPublic() { pod.isPublic	}
}
