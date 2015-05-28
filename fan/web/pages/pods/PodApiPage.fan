using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRouting = true }
const mixin PodApiPage : PrPage {

	@PageContext	abstract FandocApiUri		fandocUri
	
	RepoPod pod() {
		fandocUri.pod
	}

	DocType type() {
		fandocUri.type
	}
	
	LinkResolverCtx ctx() {
		LinkResolverCtx(pod) { it.type = fandocUri.typeName }
	}
	
	override Bool isPublic() { pod.isPublic	}
}
