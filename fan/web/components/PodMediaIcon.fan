using afIoc::Inject
using afEfanXtra
using afPillow

const mixin PodMediaIcon : PrComponent {

	abstract RepoPod	pod
	
	@InitRender
	Void initRender(RepoPod pod) {
		this.pod = pod
	}
	
	override Str renderTemplate() {
		iconUri := pod.toSummaryUri.toDocUri(`/doc/icon.png`)
		iconUrl := (Uri) (iconUri.exists ? iconUri.toAsset.clientUrl : fileHandler.fromLocalUrl(`/images/defaultPodIcon.png`))
		return """<img class="podMediaIcon" src="${iconUrl.encode}" alt="${pod.projectName} ${pod.version}">"""
	}
	
}
