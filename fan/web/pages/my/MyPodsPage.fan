using afIoc
using afBedSheet
using afFormBean
using afEfanXtra
using afPillow

const mixin MyPodsPage : PrMyPage {
	
	@Inject abstract FanrRepo		fanrRepo
	@Inject abstract RepoPodDao		podDao
	@Inject { type=PodUploadDetails# } 
			abstract FormBean		formBean
			abstract RepoPod[]		allPods

	@InitRender
	Void initRender() {
		allPods = podDao.findPrivate(userSession.user)
		injector.injectRequireModule("fileInput")
	}
	
	Str podSummaryUrl(RepoPod pod) {
		// FIXME: use FandocUri
		pages[PodsPage#].pageUrl.plusSlash.plusName(pod.name).encode
	}
	Str podApiUrl(RepoPod pod) {
		pages[PodsPage#].pageUrl.plusSlash.plusName(pod.name, true).plusName("api", true).encode
	}
	Str podDocsUrl(RepoPod pod) {
		pages[PodsPage#].pageUrl.plusSlash.plusName(pod.name, true).plusName("doc", true).encode
	}
	Str userUrl(RepoUser user) {
		pages[UsersPage#].withContext([user]).pageUrl.encode
	}
	Str downloads(Obj o) {
		""
	}
	
	Str uploadUrl() {
		pageMeta.eventUrl(#onUpload).encode
	}

	@PageEvent { httpMethod="POST" }
	Redirect? onUpload() {
		try {
			RepoPod? pod
	        httpRequest.parseMultiPartForm |Str inputName, InStream in, Str:Str headers| {
				if (inputName == "podFile")
					pod = fanrRepo.publish(userSession.user, in)
	        }

//			userActivity.logLoggedIn
			if (pod != null)
				alert.msg = Msgs.alert_userUploadedPod(pod)
			return Redirect.afterPost(pages[MyPodsPage#].pageUrl)

		} catch (PodPublishErr err) {
			formBean.errorMsgs.add(err.msg)
			return null
		}
	}
}

class PodUploadDetails { }