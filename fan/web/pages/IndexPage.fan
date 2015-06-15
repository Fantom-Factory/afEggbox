using afIoc
using afIocConfig
using afBedSheet
using afDuvet
using afEfanXtra

const mixin IndexPage : PrPage {

	@Inject abstract BedSheetServer	bedServer
	@Inject	abstract RepoPodDao		podDao
			abstract RepoPod[]		newPods
			abstract RepoPod[]		newVers
	
	@InitRender
	Void initRender() {
		this.newPods = _newPods
		this.newVers = _newVers
	}
	
	** Need to wait until *after* layout has rendered to find the HTML tag.
	@AfterRender
	Void afterRender(StrBuf buf) {
		htmlIndex	:= buf.toStr.index("<html ") + "<html ".size
		absImgUrl	:= bedServer.toAbsoluteUrl(fileHandler.fromLocalUrl(`/images/ogimage.png`).clientUrl)

		// ---- Open Graph Meta ---- Mandatory
		buf.insert(htmlIndex, "prefix=\"og: http://ogp.me/ns#\" ")
		injector.injectMeta.withProperty("og:type"	).withContent("website")
		injector.injectMeta.withProperty("og:title"	).withContent("Fantom Pod Repository")
		injector.injectMeta.withProperty("og:url"	).withContent(bedServer.host.encode)
		injector.injectMeta.withProperty("og:image"	).withContent(absImgUrl.encode)
		
		// ---- Open Graph Meta ---- Optional
		injector.injectMeta.withProperty("og:description"	).withContent("3rd Party Libraries for the Fantom programming language")
		injector.injectMeta.withProperty("og:locale"		).withContent("en_GB")
		injector.injectMeta.withProperty("og:site_name"		).withContent("Fantom Pod Repository")
	}
	
	RepoPod[] _newPods() {
		pods := podDao.findPublicNewest(loggedInUser).sortr(RepoPodDao.byBuildDate)
		idx  := 0
		return pods.map |oldPod| { 
			if (idx >= 10)
				return null
			newPod := podDao.findOne(oldPod.name)
			if (newPod.isDeprecated)
				return null
			idx ++
			return newPod
		}.exclude { it == null }
	}

	RepoPod[] _newVers() {
		pods := podDao.findPublic(loggedInUser).sortr(RepoPodDao.byBuildDate)
		return pods.size < 10 ? pods : pods[0..<10]
	}
}
