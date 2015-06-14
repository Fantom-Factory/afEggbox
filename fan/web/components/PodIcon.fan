using afIoc::Inject
using afEfanXtra
using afPillow

const mixin PodIcon : EfanComponent {

	@Inject	abstract Pages	 	pages
			abstract RepoPod	pod
	
	@InitRender
	Void initRender(RepoPod pod) {
		this.pod = pod
	}
	
	override Str renderTemplate() {
		if (!pod.hasIcon)
			return ""
		
		iconUrl := pod.iconDataUri ?: pod.toDocUri(`/doc/icon.png`).toClientUrl.encode

		return """<img class="podIcon" src="${iconUrl}">"""
	}
	
}
