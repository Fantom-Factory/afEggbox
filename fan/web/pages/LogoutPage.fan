using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afFormBean

const mixin LogoutPage : PrPage {

	@InitRender
	Void initRender() {
		user := userSession.logout
		if (user != null)
			alert.msg = Msgs.alert_userLoggedOut(user)
		throw ReProcessErr(Redirect.afterPost(pages[LoginPage#].pageUrl))
	}
	
	override Str renderTemplate() { "" }

}
