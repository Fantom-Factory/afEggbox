using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodSummaryPage : PrPage {

	@Inject	abstract HtmlWriter		htmlWriter
	@PageContext
			abstract RepoPod		pod

		// TODO: seo this page!
	
	Str podEditUrl() {
		`/pods/${pod.name}/${pod.version}/edit`.encode
	}
	
	Str aboutPod() {
		htmlWriter.toHtml(pod.aboutFandoc)
	}
}
