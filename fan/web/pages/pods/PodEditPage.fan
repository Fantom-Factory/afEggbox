using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afFormBean

@Page { disableRouting = true }
const mixin PodEditPage : PrPage {

					abstract RepoPod		pod
	@Inject 		abstract RepoPodDao		podRepo
	@Inject 		abstract FanrRepo		fanrRepo
	@Inject 		abstract Scope			scope
	@Inject { type=PodEditDetails# } 
					abstract FormBean		podEditFormBean
					abstract PodEditDetails	editDetails
	@Inject { type=PodDeleteDetails# } 
					abstract FormBean		podDeleteFormBean

	@InitRender
	Void initRender(RepoPod pod) {
		this.pod		 = pod
		this.editDetails = PodEditDetails(pod)
	}

	Str:Str[] invalidLinkMap() {
		map := Str:Str[][:] { ordered = true }
		pod.invalidLinks.each |link| {
			map.getOrAdd(link.where.toClientUrl.encode) { Str[,] }.add("<code>${link.link.toXml}</code> - ${link.msg.toXml}")
		}
		return map
	}
	
	FandocSummaryUri podSummaryUrl() {
		scope.build(FandocSummaryUri#, [pod.name, pod.version])
	}

	Str saveUrl() {
		`/pods/${pod.name}/${pod.version}/edit/save`.encode
	}

	Str validateUrl() {
		`/pods/${pod.name}/${pod.version}/edit/validate`.encode
	}
	
	Str deleteUrl() {
		`/pods/${pod.name}/${pod.version}/edit/delete`.encode
	}

	Bool isPublic() {
		pod.isPublic
	}

	@PageEvent { httpMethod="POST" }
	Redirect? onSave() {
		if (!podEditFormBean.validateForm(httpRequest.body.form))
			return null

		podEditFormBean.updateBean(editDetails)
		if (pod.isPublic) {
			if (editDetails.summary.isEmpty)
				podEditFormBean.formFields[PodEditDetails#summary].errMsg = "Public pods must have a summary"
			
			if (editDetails.licenceName.isEmpty)
				podEditFormBean.formFields[PodEditDetails#licenceName].errMsg = "Public pods must have a licence"
			
			if (editDetails.organisationUrl.toStr.isEmpty && editDetails.sourceCodeManagementUrl.toStr.isEmpty) {
				podEditFormBean.errorMsgs.add("Public pods must have an Org URL or a Source Code URL")
				podEditFormBean.formFields[PodEditDetails#organisationUrl].invalid = true
				podEditFormBean.formFields[PodEditDetails#sourceCodeManagementUrl].invalid = true
			}
	
			if (podEditFormBean.hasErrors)
				return null
		}		
		
		podRepo.update(pod)
		logUserPodActivity(pod, LogMsgs.updatedPod, pod._id)
		
		alert.success = Msgs.alert_podUpdated(pod)
		return Redirect.afterPost(pages[MyPodsPage#].pageUrl)
	}

	@PageEvent { httpMethod="POST" }
	Redirect? onValidate() {
		pod.validateDocumentLinks.save
		return Redirect.afterPost(podSummaryUrl.toClientUrl.plusSlash.plusName("edit"))
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
			logUserPodActivity(pod, LogMsgs.deletedPod, pod._id)
			
			alert.success = Msgs.alert_podDeleted(pod)
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

	// TODO I dunno why these fields need to be non-nullable?
	
	@HtmlInput { type="text"; attributes="autocomplete=\"off\""; minLength=3; maxLength=128; required=false }
	Str projectName {
		get { pod.meta.projectName }
		set { pod.meta.projectName  = it }
	}

	@HtmlInput { type="url"; minLength=3; maxLength=512; required=false }
	Uri podUrl {
		get { pod.meta.podUrl ?: `` }
		set { pod.meta.podUrl  = it }
	}

	@HtmlInput { type="textarea"; attributes="rows=\"3\""; minLength=3; maxLength=1024 }
	Str summary {
		get { pod.meta.summary }
		set { pod.meta.summary  = it }
	}

	@HtmlInput { type="checkbox" }
	Bool isPublic {
		get { pod.meta.isPublic }
		set { pod.meta.isPublic = it	}
	}

	@HtmlInput { type="checkbox" }
	Bool isDeprecated {
		get { pod.meta.isDeprecated }
		set { pod.meta.isDeprecated = it }
	}

	@HtmlInput { type="checkbox" }
	Bool isInternal {
		get { pod.meta.isInternal }
		set { pod.meta.isInternal = it }
	}

	@HtmlInput { type="text"; minLength=3; maxLength=256; required=false }
	Str organisationName {
		get { pod.meta.orgName ?: "" }
		set { pod.meta.orgName  = it }
	}

	@HtmlInput { type="url"; minLength=3; maxLength=512; required=false }
	Uri organisationUrl {
		get { pod.meta.orgUrl ?: `` }
		set { pod.meta.orgUrl  = it }
	}

	@HtmlInput { type="text"; minLength=3; maxLength=128; required=false }
	Str licenceName {
		get { pod.meta.licenceName ?: "" }
		set { pod.meta.licenceName  = it }
	}

	@HtmlInput { type="text"; minLength=3; maxLength=128; required=false }
	Str sourceCodeManagement {
		get { pod.meta.vcsName ?: "" }
		set { pod.meta.vcsName  = it }
	}

	@HtmlInput { type="url"; minLength=3; maxLength=512; required=false }
	Uri sourceCodeManagementUrl {
		get { pod.meta.vcsUrl ?: `` }
		set { pod.meta.vcsUrl  = it }
	}	

	@HtmlInput { type="text"; minLength=3; maxLength=256; required=false }
	Str tags {
		get { pod.meta.tags.join(", ") }
		set { pod.meta.tags = it.split(',') }
	}	
}

class PodDeleteDetails {
	@HtmlInput { type="text"; attributes="autocomplete=\"off\""; required=true; minLength=3; maxLength=128 }
	Str?	podName
}
