using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afFormBean

@Page { disableRoutes = true }
const mixin PodEditPage : PrPage {

	@PageContext	abstract RepoPod		pod
	@Inject 		abstract FanrRepo		fanrRepo 
	@Inject { type=PodDeleteDetails# } 
					abstract FormBean		podDeleteFormBean

	Str deleteUrl() {
		pageMeta.eventUrl(#onDelete).encode
	}

	@PageEvent { httpMethod="POST" }
	Redirect? onDelete() {
		if (!podDeleteFormBean.validateForm(httpRequest.body.form))
			return null

		podDeleteDetails := (PodDeleteDetails) podDeleteFormBean.createBean
		
		if (podDeleteDetails.podName != pod.name) {
			podDeleteFormBean.errorMsgs.add(Msgs.podDelete_podNameDoesNotMatch(pod.name))
			return null						
		}

		try {
			fanrRepo.delete(userSession.user, pod)
	//		userActivity.logPodDeleted
			
			alert.msg = Msgs.alert_podDeleted(pod)
			return Redirect.afterPost(pages[MyPodsPage#].pageUrl)

		} catch (PodDeleteErr err) {
			podDeleteFormBean.errorMsgs.add(err.msg)
			return null
		}
	}
}

class PodDeleteDetails {
	@HtmlInput { type="text"; placeholder="Pod Name"; attributes="autocomplete=\"off\""; required=true; minLength=3; maxLength=128 }
	Str?	podName
}
