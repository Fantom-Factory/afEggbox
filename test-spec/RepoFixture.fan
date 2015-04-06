using afBounce
using afFancordion
using afIoc
//using concurrent
//using afSizzle

** The super class for all Web Fixtures
abstract class RepoFixture : FixtureTest {
    BedClient? client

	@Inject RepoPodDao?			podDao
	@Inject RepoPodFileDao?		podFileDao
	@Inject RepoUserDao?		userDao

    virtual Void setupFixture() {
		podDao.dropAll
		podFileDao.dropAll
		userDao.dropAll
    }

    virtual Void tearDownFixture() { }

    // The important bit - this creates the FancordionRunner to be used.
    override FancordionRunner fancordionRunner() {
        RepoRunner()
    }

    // Other common / reusable methods such as :
	
//	Void loginAs(Str name) {
//		user := userDao[name]	// assert user exists
//		client.webSession(true)[UserSession#.qname] = UserSessionState { it.name = name }
//	}

	Void logout() {
		client.webSession?.delete
	}

//	Type gotoPage(Str pageName, Obj? ctx := null) {
//		pageType := Pod.of(this).type(pageName.fromDisplayName.capitalize)
//		pageUrl	 := ctx == null ? pages[pageType].pageUrl : pages[pageType].withContext([ctx]).pageUrl
//		client.get(pageUrl)
//		return pageType
//	}
//
//	Void showPage(Str pageName, Obj? ctx := null) {
//		pageType := gotoPage(pageName, ctx)
//		verifyEq(renderedPageType, pageType)
//	}
	
	Void echoPage() {
		echo(Element("html").html)
	}
	
	Type renderedPageType() {
		Type.find(client.lastResponse.headers["X-afPillow-renderedPage"])
	}
	
	Str renderedPageName() {
		renderedPageType.name.toDisplayName.lower
	}
	
//	Str renderComponent(Type componentType, Obj[] context) {
//		html := efanXtra.component(componentType).render(context)
//		Actor.locals["afBounce.sizzleDoc"] = SizzleDoc.fromStr(html)
//		return html
//	}
	
	FormInput input(Str css) {
		FormInput(css)
	}

	RepoUser newUser(Str userName := "Wotever") {
		RepoUser {
			it.userName		= userName
			it.realName		= "Wot Ever"
			it.passwordHash	= "wotever"
			it.email		= `wotever@wotever.com`
		}
	}	
}
