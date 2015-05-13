using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodDocsPage : PrPage {

	@Inject			abstract HtmlWriter		htmlWriter
	@Inject			abstract RepoPodDocsDao	podDocsDao
	@PageContext	abstract RepoPod		pod
	@PageContext	abstract Uri			fileUri

	Str docs() {
		fandoc := podDocsDao.find(pod.name, pod.version)[fileUri]?.readAllStr
		if (fandoc == null)
			throw HttpStatusErr(404, "Pod file `${fileUri}` not found")
		return htmlWriter.toHtml(fandoc)
	}
}
