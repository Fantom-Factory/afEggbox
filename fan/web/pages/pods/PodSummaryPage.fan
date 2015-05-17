using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodSummaryPage : PrPage {

	@Inject	abstract Fandoc			fandoc
	@PageContext
			abstract RepoPod		pod
//			abstract Uri			podUri
	
//	@BeforeRender
//	Void beforeRender() {
//		this.podUri = `/pods/${pod.name}/${pod.version}`
//	}

		// TODO: seo this page!
	
	Str podUrl(Uri url) {
		if (url == `/edit`)
			return `/pods/${pod.name}/${pod.version}/edit`.encode	// TODO: remove version on latest pod
		return resolve(pod, url)
	}
	
	Str aboutPod() {
		fandoc.writeStrToHtml(pod.aboutFandoc)
	}
}
