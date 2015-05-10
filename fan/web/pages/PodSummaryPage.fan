using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { url=`/pods` }
const mixin PodSummaryPage : PrPage {

	@Inject	abstract RepoPodDao	podDao
			abstract RepoPod?	pod

	@InitRender
	Void initRender(Str? podName := null, Str? podVersion := null) {
		// --> /pods/
		if (podName == null)
			throw ReProcessErr(Redirect.movedTemporarily(pages[PodsPage#].pageUrl))
		
		// --> /pods/afSlim
		// --> /pods/afSlim/
		if (podName != null && podVersion == null)
			throw ReProcessErr(Redirect.movedTemporarily(pageMeta.withContext([podName, "latest"]).pageUrl))

		if (podVersion.equalsIgnoreCase("latest"))
			podVersion = null

		// --> /pods/afSlim/oops
		version := (Version?) null
		if (podVersion != null) {
			version = Version(podVersion, false)
			if (version == null)
				throw HttpStatusErr(404, "Pod ${podName} v${podVersion} not found")			
		}

		pod = podDao.findOne(podName, version)
		
		// --> /pods/afSlim/666
		if (pod == null) {
			v := version != null ? " v${version}" : ""
			throw HttpStatusErr(404, "Pod ${podName}${v} not found")
		}
		
		// TODO: seo this page!
	}
}
