using afIoc::Inject
using afEfanXtra
using afPillow

const mixin PodBreadcrumbs : PrComponent {

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

		if (!fandocUri.isLatest)
			html.add("""<div class="alert alert-warning" role="alert"><b>Warning:</b> This page pertains to an older version of ${fandocUri.pod.projectName}. <a href="${fandocUri.toLatest.toClientUrl.encode}">Click here for the latest.</a></div>""")

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
		
		href := fandocUri.toSummaryUri.toClientUrl.plusSlash.plusName("feed.atom").encode
		injector.injectLink
			.setAttr("rel",		"alternate")
			.setAttr("type",	"application/atom+xml")
			.setAttr("title",	"${fandocUri.pod.projectName} Versions")
			.setAttr("href",	href)

		html.add("""<a href="${href}" class="podRssFeed" title="RSS Feed for ${fandocUri.pod.projectName}"><i class="fa fa-rss-square fa-lg rss"></i></a>""")
		
		html.add("</ol>")

		return html.toStr
	}
	
}
