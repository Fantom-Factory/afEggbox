using afIoc
using afIocConfig
using afDuvet
using afEfanXtra
 
const mixin TopNavBarPublic : PrComponent { 

	@Config
	@Inject abstract Bool			aboutFandocExists

	@InitRender
	Void init() {
//		injector.injectRequireModule("bootstrap")
	}
	
	Str pageLink(Type page, Str name) {
		html := (pageMeta.pageType == page) ? """<li class="active">""" : "<li>"
		html += """<a href="${pageUrl(page)}">${name}</a>"""
		html += "</li>"
		return html
	}
	
	Str helpDdCss() {
		pageMeta.pageType.fits(PrHelpPage#) ? "active" : ""
	}
}
