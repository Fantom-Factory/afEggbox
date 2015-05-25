using afIoc
using afDuvet
using afEfanXtra
 
const mixin TopNavBarPrivate : PrComponent { 

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

	Str userLink(Str name) {
		html := (pageMeta.pageType == UsersPage# && pageMeta.pageContext.first == loggedInUser.screenName) ? """<li class="active">""" : "<li>"
		html += """<a href="${pageUrl(UsersPage#, [loggedInUser])}">${name}</a>"""
		html += "</li>"
		return html
	}
}
