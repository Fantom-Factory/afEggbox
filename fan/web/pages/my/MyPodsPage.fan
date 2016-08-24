using afIoc
using afBedSheet
using afFormBean
using afEfanXtra
using afPillow
using afSitemap

const mixin MyPodsPage : PrMyPage, SitemapExempt {
	
	@Inject abstract Scope			scope
	@Inject abstract FanrRepo		fanrRepo
	@Inject abstract RepoPodDao		podDao
	@Inject { type=PodUploadDetails# } 
			abstract FormBean		formBean
			abstract RepoPod[]		allPods

	@InitRender
	Void initRender() {
		allPods = podDao.findLatestPods(userSession.user)
		injector.injectRequireModule("fileInput")
		injector.injectRequireModule("rowLink")
	}
	
	Str s(Int size) {
		size > 1 ? "s" : "" 
	}

	Str podSummaryUrl(RepoPod pod) {
		fandocUri(pod).toSummaryUri.toClientUrl.encode
	}

	Str podDocsHtml(RepoPod pod) {
		apiUri := fandocUri(pod).toApiUri
		docUri := fandocUri(pod).toDocUri
		if (pod.hasApi && pod.hasDocs)
			return "<a href=\"${apiUri.toClientUrl.encode}\">API</a> / <a href=\"${docUri.toClientUrl.encode}\">User Guide</a>" 
		if (pod.hasApi)
			return "<a href=\"${apiUri.toClientUrl.encode}\">API</a>" 
		if (pod.hasDocs)
			return "<a href=\"${docUri.toClientUrl.encode}\">User Guide</a>"
		return ""
	}

	Str podEditUrl(RepoPod pod) {
		pages[PodsIndexPage#].pageUrl.plusSlash.plusName(pod.name).plusSlash.plusName("edit").encode
	}

	Str podDeleteUrl(RepoPod pod) {
		pages[PodsIndexPage#].pageUrl.plusSlash.plusName(pod.name).plusSlash.plus(`edit#delete`).encode
	}

	Str podValidateUrl(RepoPod pod) {
		pages[PodsIndexPage#].pageUrl.plusSlash.plusName(pod.name).plusSlash.plus(`edit#validate`).encode
	}

	private FandocUri fandocUri(RepoPod pod) {
		scope.build(FandocSummaryUri#, [pod.name, pod.version])
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

			if (pod != null) {
				logUserPodActivity(pod, LogMsgs.uploadedPod, pod._id)
				alert.success = Msgs.alert_userUploadedPod(pod)
			}
			return Redirect.afterPost(pages[MyPodsPage#].pageUrl)

		} catch (PodPublishErr err) {
			formBean.errorMsgs.add(err.msg)
			return null
		}
	}
}

class PodUploadDetails { }