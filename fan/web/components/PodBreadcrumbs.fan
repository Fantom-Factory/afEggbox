using afIoc::Inject
using afEfanXtra
using afPillow

const mixin PodBreadcrumbs : EfanComponent {

	@Inject	abstract Pages	 	pages
			abstract FandocUri	fandocUri
	
	@InitRender
	Void initRender(FandocUri fandocUri) {
		this.fandocUri = fandocUri
	}
	
	Str podsUrl() {
		pages[PodsPage#].pageUrl.encode
	}

	override Str renderTemplate() {
		html := StrBuf()
		html.add("<ol class=\"breadcrumb\">")
		html.add("<li>")
		html.add("<a href=\"${podsUrl}\">Pods</a>")
		html.add("</li>")
		
		uris := FandocUri[,]
		uri  := (FandocUri?) fandocUri
		while (uri != null) {
			uris.insert(0, uri)
			uri = uri.toParentUri
		}
		
		uris.eachRange(0..<-1){
			html.add("<li>")
			html.add("<a href=\"${it.toClientUrl.encode}\">${it.title.toXml}</a>")
			html.add("</li>")
		}
		html.add("<li class=\"active\">${uris.last.title.toXml}</li>")
		
		html.add("</ol>")
		return html.toStr
	}
	
}
