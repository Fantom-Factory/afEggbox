using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodSummaryPage : PrPage {

	@Inject	abstract Fandoc			fandoc
	@PageContext
			abstract RepoPod		pod

		// TODO: seo this page!
	
	Str podEditUrl() {
		`/pods/${pod.name}/${pod.version}/edit`.encode
	}
	
	Str aboutPod() {
		fandoc.writeStrToHtml(pod.aboutFandoc)
	}
}
