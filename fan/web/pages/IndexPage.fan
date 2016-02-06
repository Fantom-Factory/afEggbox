using afIoc
using afIocConfig
using afBedSheet
using afDuvet
using afEfanXtra

const mixin IndexPage : PrPage {
	private static const Int noOfPodsInList	:= 5
	
	@Inject	abstract RepoPodDao		podDao
			abstract RepoPod[]		newPods
			abstract RepoPod[]		newVers
			abstract RepoPod[]		allPods
	
	@InitRender
	Void initRender() {
		this.allPods = podDao.findLatestPods.exclude { it.isDeprecated }
		this.newPods = _newPods
		this.newVers = _newVers

	}
	
	** Need to wait until *after* layout has rendered to find the HTML tag.
	@AfterRender
	Void afterRender(StrBuf buf) {
		htmlIndex	:= buf.toStr.index("<html ") + "<html ".size
		absImgUrl	:= bedServer.toAbsoluteUrl(fileHandler.fromLocalUrl(`/images/ogimage.jpg`).clientUrl)

		// ---- Open Graph Meta ---- Mandatory
		buf.insert(htmlIndex, "prefix=\"og: http://ogp.me/ns#\" ")
		injector.injectMeta.withProperty("og:type"	).withContent("website")
		injector.injectMeta.withProperty("og:title"	).withContent("Fantom Pod Repository")
		injector.injectMeta.withProperty("og:url"	).withContent(bedServer.host.encode)
		injector.injectMeta.withProperty("og:image"	).withContent(absImgUrl.encode)
		
		// ---- Open Graph Meta ---- Optional
		injector.injectMeta.withProperty("og:description"	).withContent("A website for uploading, viewing and downloading 3rd Party Fantom libraries")
		injector.injectMeta.withProperty("og:locale"		).withContent("en_GB")
		injector.injectMeta.withProperty("og:site_name"		).withContent("Fantom Pod Repository")
		
		injector.injectMeta.withName("description").withContent("A website for uploading, viewing and downloading 3rd Party Fantom libraries")
		
		injector.injectRequireModule("podSearch")
	}
	
	RepoPod[] _newPods() {
		pods := podDao.findOldestPods.sortr(RepoPodDao.byBuildDate)
		idx  := 0
		return pods.map |oldPod| { 
			if (idx >= noOfPodsInList)
				return null
			newPod := podDao.findPod(oldPod.name)
			if (newPod.isDeprecated)
				return null
			idx ++
			return newPod
		}.exclude { it == null }
	}

	RepoPod[] _newVers() {
		pods := podDao.findLatestPods.sortr(RepoPodDao.byBuildDate)
		return pods.size < noOfPodsInList ? pods : pods[0..<noOfPodsInList]
	}
}
