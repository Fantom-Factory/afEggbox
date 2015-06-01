using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodApiPage : PrPage {

	@PageContext	abstract FandocApiUri		fandocUri
	
//	@BeforeRender
//	Void beforeRender() {
//		injector.injectRequireModule("anchorJS", null, ["dt"])
//	}

	RepoPod pod() {
		fandocUri.pod
	}

	DocType type() {
		fandocUri.type
	}
	
	LinkResolverCtx ctx() {
		LinkResolverCtx(pod) { it.type = fandocUri.typeName }
	}
	
	Bool isPublic() {
		pod.isPublic
	}
}
