using afPillow
using afEfanXtra

@Page { disableRoutes=true }
const mixin Error404Page : PrPage {
	
	@InitRender
	Void initRender() {
		injector.injectRequireModule("notFound")
	}
}
