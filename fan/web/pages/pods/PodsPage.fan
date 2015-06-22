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
		allPods	= podDao.findLatestPods.exclude { it.isDeprecated }
		if (sortByName)
			allPods = allPods.sort(RepoPodDao.byProjName)
		else
			allPods = allPods.sortr(RepoPodDao.byBuildDate)
		injector.injectRequireModule("rowLink")
		countPublicVersions = podDao.countVersions(null)
		countPublicPods		= podDao.countPods(null)
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
}
