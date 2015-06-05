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
		iconUrl := (Str?) null

		if (!pod.hasIcon)
			iconUrl = fileHandler.fromLocalUrl(`/images/defaultPodIcon.png`).clientUrl.encode
		else if (pod.iconDataUri != null)
			iconUrl = pod.iconDataUri
		else
			iconUrl = pod.toDocUri(`/doc/icon.png`).toClientUrl.encode

		return """<img class="podMediaIcon" src="${iconUrl}" alt="${pod.projectName} ${pod.version}">"""
	}
	
}
