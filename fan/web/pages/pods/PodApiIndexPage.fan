using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodApiIndexPage : PrPage {

	@PageContext	abstract FandocApiUri	fandocUri

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
