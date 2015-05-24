using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodApiPage : PrPage {

	@PageContext	abstract FandocApiUri		fandocUri
	
	RepoPod pod() {
		fandocUri.pod
	}

	DocType type() {
		fandocUri.type
	}
	
	LinkResolverCtx ctx() {
		// FIXME:
		LinkResolverCtx(pod) { it.type = fandocUri.typeName }
	}
}
