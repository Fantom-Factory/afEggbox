using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afFormBean

const mixin LogoutPage : PrPage {

	@InitRender
	Void initRender() {
		userSession.logout
		throw ReProcessErr(Redirect.afterPost(pages[LoginPage#].pageUrl))
	}
	
	override Str renderTemplate() { "" }

}
