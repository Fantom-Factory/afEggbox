using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using syntax
using web

@Page { disableRoutes = true }
const mixin PodSrcPage : PrPage {

	@PageContext	abstract FandocSrcUri	fandocUri

	
	@BeforeRender
	Void beforeRender() {
		if (fandocUri.toClientUrl != bedServer.toClientUrl(httpRequest.url) )
			throw ReProcessErr(Redirect.movedTemporarily(fandocUri.toClientUrl))
	}

	RepoPod pod() {
		fandocUri.pod
	}
	
	Bool isPublic() {
		pod.isPublic
	}
}
