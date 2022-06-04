using afBounce

** Private Pod Versions
** ####################
** 
** If the latest version of a pod is private, and the other versions are public, ensure the correct 
** pod versions are displayed in lists and that the fandoc URLs point to the latest public one.
** 
** Example Script
** --------------
** 1. [Setup test]`exe:script1` 
** 1. Goto the [Index Page]`exe:showPage(#TEXT)`
** 1. [Check latestPod]`exe:checkLatestPod`
class TestPrivatePodVersions : WebFixture {

	Void script1() {
		userDao.create(newUser("micky.mouse@disney.com", "password"))
		uploadPod("foo-1.0.pod")
		uploadPod("foo-2.0.pod")
		pod := podDao.get("foo-2.0")
		pod.meta.isPublic = false
		pod.save
	}
	
	Void checkLatestPod() {
		podLink := Link(".latestPods .podList .media-heading a")[0]
		podLink.verifyHrefEq(`/pods/foo`)
		podLink.verifyTextEq("Foo 1.0")

		podLink = Link(".latestVersions .podList .media-heading a")[0]
		podLink.verifyHrefEq(`/pods/foo`)
		podLink.verifyTextEq("Foo 1.0")
	}

	Void uploadPod(Str podName) {
		user := userDao.getByEmail("micky.mouse@disney.com")
		scope.registry.activeScope.createChild("httpRequest") {
			fanrRepo.publish(user, `test/res/${podName}`.toFile.in)
		}
	}

}
