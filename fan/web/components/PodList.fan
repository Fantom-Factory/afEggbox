using afIoc::Inject
using afEfanXtra
using afPillow

const mixin PodList : PrComponent {
	
			abstract RepoPod[]	pods
	
	@InitRender
	Void initRender(RepoPod[] pods) {
		this.pods = pods
	}
	
	Str podSummaryUrl(RepoPod pod) {
		pod.toSummaryUri.toClientUrl.encode
	}

	Str podDocsHtml(RepoPod pod) {
		if (pod.hasApi && pod.hasDocs)
			return "<a href=\"${pod.toApiUri.toClientUrl.encode}\">API</a> / <a href=\"${pod.toDocUri.toClientUrl.encode}\">User Guide</a>" 
		if (pod.hasApi)
			return "<a href=\"${pod.toApiUri.toClientUrl.encode}\">API</a>" 
		if (pod.hasDocs)
			return "<a href=\"${pod.toDocUri.toClientUrl.encode}\">User Guide</a>"
		return ""
	}
	
	Str editUrl(RepoPod pod) {
		pod.toSummaryUri.toClientUrl.plusSlash.plusName("edit").encode
	}
}
