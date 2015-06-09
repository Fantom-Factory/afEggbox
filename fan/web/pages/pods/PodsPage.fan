using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodsPage : PrPage {

	@Inject abstract Registry		registry
	@Inject abstract RepoPodDao		podDao
			abstract RepoPod[]		allPods
			abstract Int			countPublicVersions
			abstract Int			countPublicPods
			abstract Bool			sortByName

	@InitRender
	Void initRender() {
		sortByName	= httpRequest.url.query.containsKey("sortByName")
		echo(sortByName)
		allPods	= podDao.findPublic(loggedInUser).exclude { it.isDeprecated }
		if (sortByName)
			allPods = allPods.sort(RepoPodDao.byProjName)
		else
			allPods = allPods.sortr(RepoPodDao.byBuildDate)
		injector.injectRequireModule("rowLink")
		countPublicVersions = podDao.countPublicVersions(null)
		countPublicPods		= podDao.countPublicPods(null)
	}
	
	Str s(Int size) {
		size > 1 ? "s" : "" 
	}
	
	Str nameActive() {
		sortByName ? "active" : ""
	}
	
	Str dateActive() {
		sortByName ? "" : "active"
	}
	
	Str podSummaryUrl(RepoPod pod) {
		pod.toSummaryUri.toClientUrl.encode
	}

	Str podDocsHtml(RepoPod pod) {
		if (pod.hasApi && pod.hasDocs)
			return "<a href=\"${pod.toApiUri.toClientUrl.encode}\">API</a> / <a href=\"${pod.toDocUri.toClientUrl.encode}\">User Guide</a>" 
		if (pod.hasApi)
			return "<a href=\"${pod.toApiUri.toClientUrl.encode}\">API</a>" 
		if (pod.hasDocs)
			return "<a href=\"${pod.toDocUri.toClientUrl.encode}\">User Guide</a>"
		return ""
	}
	
	Str editUrl(RepoPod pod) {
		pod.toSummaryUri.toClientUrl.plusSlash.plusName("edit").encode
	}
}
