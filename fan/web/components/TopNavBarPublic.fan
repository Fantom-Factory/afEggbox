using afIoc
using afDuvet
using afEfanXtra
 
const mixin TopNavBarPublic : PrComponent { 

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
}
