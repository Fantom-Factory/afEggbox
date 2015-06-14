using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using fandoc

@Page { disableRoutes = true }
const mixin PodDocPage : PrPage {

	@PageContext	abstract FandocDocUri		fandocUri

	@BeforeRender
	Void beforeRender() {
		injector.injectRequireModule("anchorJS", null, [".fandoc h2, .fandoc h3, .fandoc h4"])
	}

	RepoPod pod() {
		fandocUri.pod
	}

	Str docHtml() {
		fandocUri.docHtml
	}
	
	Str apiUrl() {
		fandocUri.toApiUri.toClientUrl.encode
	}
	
	Bool isPublic() {
		pod.isPublic
	}
}
