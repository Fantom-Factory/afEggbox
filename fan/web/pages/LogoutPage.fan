using afBedSheet
using afEfanXtra
using afSitemap

const mixin LogoutPage : PrPage, SitemapExempt {

	@InitRender
	Void initRender() {
		user := userSession.logout
		if (user != null)
			alert.success = Msgs.alert_userLoggedOut(user)
		throw ReProcessErr(Redirect.afterPost(pages[LoginPage#].pageUrl))
	}
	
	override Str renderTemplate() { "" }

}
