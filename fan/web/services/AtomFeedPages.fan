using afIoc
using afBedSheet

const class AtomFeedPages {

	@Inject private const RepoPodDao		podDao
	@Inject private const AtomFeedGenerator	atomFeedGen
	
	new make(|This|in) { in(this) }
	
	Text generateAll() {
		pods := podDao.findPublicVersions(20)
		feed := atomFeedGen.generate(`/pods/feed.atom`, pods, "Fantom Pod Repository", "3rd Party Libraries for the Fantom language", "Fantom Pods")
		return Text.fromContentType(feed, MimeType("application/atom+xml"))
	}

	Obj generateForPod(Str podName) {
		pods := podDao.findVersions(null, podName, 20)
		if (pods.isEmpty)
			return HttpStatus(404, "Pod ${podName} not found") 
		feed := atomFeedGen.generate(`/pods/${podName}/feed.atom`, pods, "${pods.first.projectName} Versions", "Version history for ${pods.first.projectName}", "${pods.first.projectName} Summary")
		return Text.fromContentType(feed, MimeType("application/atom+xml"))
	}
}
