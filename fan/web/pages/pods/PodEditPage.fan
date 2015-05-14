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
		set { pod.isPublic = it }
	}

	@HtmlInput { type="text"; placeholder="Project Name"; attributes="autocomplete=\"off\""; required=true; minLength=3; maxLength=128 }
	Str projectName {
		get { pod.meta["proj.name"] ?: "" }
		set { pod.meta["proj.name"]  = it }
	}

	@HtmlInput { type="url"; placeholder="Project URL"; required=true; minLength=3; maxLength=512 }
	Str projectUrl {
		get { pod.meta["proj.uri"] ?: "" }
		set { pod.meta["proj.uri"]  = it }
	}

	@HtmlInput { type="text"; placeholder="Summary"; attributes="autocomplete=\"off\""; required=true; minLength=3; maxLength=1024 }
	Str summary {
		get { pod.meta["pod.summary"] }
		set { pod.meta["pod.summary"] = it }
	}

	@HtmlInput { type="text"; placeholder="Organisation Name"; required=true; minLength=3; maxLength=215 }
	Str organisationName {
		get { pod.meta["org.name"] ?: "" }
		set { pod.meta["org.name"]  = it }
	}

	@HtmlInput { type="url"; placeholder="Organisation URL"; required=true; minLength=3; maxLength=512 }
	Str organisationUrl {
		get { pod.meta["org.uri"] ?: "" }
		set { pod.meta["org.uri"]  = it }
	}

	@HtmlInput { type="text"; placeholder="Source Code Management"; required=true; minLength=3; maxLength=128 }
	Str sourceCodeManagement {
		get { pod.meta["vcs.name"] }
		set { pod.meta["vcs.name"] = it }
	}

	@HtmlInput { type="url"; placeholder="Source Code Management URL"; required=true; minLength=3; maxLength=512 }
	Str sourceCodeManagementUrl {
		get { pod.meta["vcs.uri"] ?: "" }
		set { pod.meta["vcs.uri"]  = it }
	}

	// TODO: edit pod fields
//license.name=The MIT Licence
//tags=database
	
}

class PodDeleteDetails {
	@HtmlInput { type="text"; placeholder="Pod Name"; attributes="autocomplete=\"off\""; required=true; minLength=3; maxLength=128 }
	Str?	podName
}
