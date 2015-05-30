using afIoc::Inject
using afEfanXtra
using afPillow

const mixin PodIcon : EfanComponent {

	@Inject	abstract Pages	 	pages
			abstract FandocUri	fandocUri
	
	@InitRender
	Void initRender(FandocUri fandocUri) {
		this.fandocUri = fandocUri
	}
	
	override Str renderTemplate() {
		iconUri := fandocUri.toDocUri(`/doc/icon.png`)
		if (!iconUri.hasDoc)
			return ""
		
		return """<img class="podIcon" src="${iconUri.toClientUrl.encode}">"""
	}
	
}
