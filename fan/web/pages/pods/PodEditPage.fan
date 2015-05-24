using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afFormBean

@Page { disableRoutes = true }
const mixin PodEditPage : PrPage {

					abstract RepoPod		pod
	@Inject 		abstract RepoPodDao		podRepo
	@Inject 		abstract FanrRepo		fanrRepo
	@Inject { type=PodEditDetails# } 
					abstract FormBean		podEditFormBean
					abstract PodEditDetails	editDetails
	@Inject { type=PodDeleteDetails# } 
					abstract FormBean		podDeleteFormBean

	@InitRender
	Void initRender(RepoPod pod) {
		this.pod = pod
		this.editDetails = PodEditDetails(pod)
	}
	
	Str podSummaryUrl(RepoPod pod) {
		// FIXME: use FandocUri
		pages[PodsPage#].pageUrl.plusSlash.plusName(pod.name).encode
	}

	Str saveUrl() {
		`/pods/${pod.name}/${pod.version}/edit/save`.encode
	}
	
	Str deleteUrl() {
		`/pods/${pod.name}/${pod.version}/edit/delete`.encode
	}

	@PageEvent { httpMethod="POST" }
	Redirect? onSave() {
		if (!podEditFormBean.validateForm(httpRequest.body.form))
			return null

		editDetails:= editDetails
		pod:=pod
		podEditFormBean.updateBean(editDetails)
		
		podRepo.update(pod)
//		userActivity.logPodUpdated
		
		alert.msg = Msgs.alert_podUpdated(pod)
		return Redirect.afterPost(pages[MyPodsPage#].pageUrl)
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
			fanrRepo.delete(loggedInUser, pod)
	//		userActivity.logPodDeleted
			
			alert.msg = Msgs.alert_podDeleted(pod)
			return Redirect.afterPost(pages[MyPodsPage#].pageUrl)

		} catch (PodDeleteErr err) {
			podDeleteFormBean.errorMsgs.add(err.msg)
			return null
		}
	}
}

class PodEditDetails {
	RepoPod	pod
	
	new make(RepoPod pod) {
		this.pod = pod
	}

	@HtmlInput { type="checkbox" }
	Bool isPublic {
		get { pod.isPublic }
		set { pod.isPublic = it	}
	}

	@HtmlInput { type="checkbox" }
	Bool isDeprecated {
		get { pod.isDeprecated }
		set { pod.isDeprecated = it }
	}

	@HtmlInput { type="checkbox" }
	Bool isInternal {
		get { pod.meta.isInternal }
		set { pod.meta.isInternal = it }
	}

	@HtmlInput { type="text"; placeholder="licenceName"; required=true; minLength=3; maxLength=128 }
	Str? licenceName {
		get { pod.meta.licenceName ?: "" }
		set { pod.meta.licenceName  = it }
	}

	@HtmlInput { type="text"; placeholder="Project Name"; attributes="autocomplete=\"off\""; required=true; minLength=3; maxLength=128 }
	Str projectName {
		get { pod.meta.projectName }
		set { pod.meta.projectName  = it }
	}

	@HtmlInput { type="url"; placeholder="Project URL"; required=true; minLength=3; maxLength=512 }
	Uri projectUrl {
		get { pod.meta.projectUrl ?: `` }
		set { pod.meta.projectUrl  = it }
	}

	@HtmlInput { type="textarea"; placeholder="Summary"; attributes="rows=\"3\""; required=true; minLength=3; maxLength=1024; hint="Summaries generally don't include the pod or project name" }
	Str summary {
		get { pod.meta.summary }
		set { pod.meta.summary  = it }
	}

	@HtmlInput { type="text"; placeholder="Organisation Name"; required=true; minLength=3; maxLength=256 }
	Str organisationName {
		get { pod.meta.orgName ?: "" }
		set { pod.meta.orgName  = it }
	}

	@HtmlInput { type="url"; placeholder="Organisation URL"; required=true; minLength=3; maxLength=512 }
	Uri organisationUrl {
		get { pod.meta.orgUrl ?: `` }
		set { pod.meta.orgUrl  = it }
	}

	@HtmlInput { type="text"; placeholder="Source Code Management"; required=true; minLength=3; maxLength=128 }
	Str sourceCodeManagement {
		get { pod.meta.vcsName ?: "" }
		set { pod.meta.vcsName  = it }
	}

	@HtmlInput { type="url"; placeholder="Source Code Management URL"; required=true; minLength=3; maxLength=512 }
	Uri sourceCodeManagementUrl {
		get { pod.meta.vcsUrl ?: `` }
		set { pod.meta.vcsUrl  = it }
	}	
}

class PodDeleteDetails {
	@HtmlInput { type="text"; placeholder="Pod Name"; attributes="autocomplete=\"off\""; required=true; minLength=3; maxLength=128 }
	Str?	podName
}
