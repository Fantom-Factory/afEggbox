using afIoc
using afPillow
using afBounce

abstract class WebFixture : RepoFixture {
	
	@Inject {}	Pages?			pages
	@Inject {}	UserSession?	userSession
	
//	override Void setupFixture() {
//		super.setupFixture
//	}
	
    // Other common / reusable methods such as :
	
	Void loginAs(Uri email) {
		user := userDao.getByEmail(email)	// assert user exists
		client.webSession(true)[UserSession#.qname] = UserSessionState { it.email = email }
	}

	Void logout() {
		client.webSession?.delete
	}

	Type gotoPage(Str pageName, Obj? ctx := null) {
		pageType := Pod.of(this).type(pageName.fromDisplayName.capitalize)
		pageUrl	 := ctx == null ? pages[pageType].pageUrl : pages[pageType].withContext([ctx]).pageUrl
		client.get(pageUrl)
		return pageType
	}

	Void showPage(Str pageName, Obj? ctx := null) {
		pageType := gotoPage(pageName, ctx)
		verifyEq(renderedPageType, pageType)
	}
	
	Void echoPage() {
		echo(Element("html").html)
	}
	
	Type renderedPageType() {
		Type.find(client.lastResponse.headers["X-afPillow-renderedPage"])
	}
	
	Str renderedPageName() {
		renderedPageType.name.toDisplayName
	}
	
	Void click(Str name) {
		SubmitButton("[name=${name.fromDisplayName}]").submitForm
	}

//	Str renderComponent(Type componentType, Obj[] context) {
//		html := efanXtra.component(componentType).render(context)
//		Actor.locals["afBounce.sizzleDoc"] = SizzleDoc.fromStr(html)
//		return html
//	}
	
	FormInput input(Str css) {
		FormInput(css)
	}
	
	Str httpStatus() {
		"${client.lastResponse.statusCode} - ${client.lastResponse.statusMsg}"
	}
}
