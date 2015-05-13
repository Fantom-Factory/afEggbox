using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodSummaryPage : PrPage {

	@Inject	abstract |->HtmlWriter|	htmlWriter
	@Inject	abstract RepoPodDao		podDao
	@PageContext
			abstract RepoPod?		pod

		// TODO: seo this page!
	
	Str aboutPod() {
		htmlWriter().toHtml(pod.aboutFandoc)
	}
}
