using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afFormBean

const mixin SignupPage : PrPage {

	@Inject abstract RepoUserDao	userDao
	@Inject	abstract HttpSession	httpSession
//	@Inject	abstract SystemActivity	systemActivity
//	@Inject abstract UserActivity	userActivity
	@Inject { type=SignUpDetails# } 
			abstract FormBean		formBean
			abstract SignUpDetails?	signUpDetails

	@BeforeRender
	Void beforeRender() {
		signUpDetails = SignUpDetails()
		formBean.formFields[SignUpDetails#password].formValue = ""
		
		// TODO: use httpSession.flashExists when BedSheet is released 
		if (httpSession.exists && httpSession.containsKey("afBedSheet.flash") && httpSession.flash["signUp.email"] != null)
			signUpDetails.email = httpSession.flash["signUp.email"]
	}

	Str signUpUrl() {
		pageMeta.eventUrl(#onSignUp).encode
	}
	
	Str formCss() {
		formBean.hasErrors ? "form-error" : "form-okay"
	}

	@PageEvent { name=""; httpMethod="POST" }
	Redirect? onSignUp() {
		if (!formBean.validateForm(httpRequest.body.form))
			return null

		signUpDetails = formBean.createBean
		
		user := userDao.getByEmail(signUpDetails.email, false)
		if (user != null) {
//			systemActivity.logFailedLogin(loginDetails.email, loginDetails.password)
			formBean.errorMsgs.add(Msgs.signup_emailTaken(user.email))
			return null
		}

		user = signUpDetails.toUser.populateFromGravatar
		userDao.create(user)
		userSession.loginAs(user)
//		userActivity.logLoggedIn
		
		alert.success = Msgs.alert_userSignedUp(user)
		return Redirect.afterPost(pages[UsersPage#].withContext([user.screenName]).pageUrl)
	}
}

class SignUpDetails {
	
	@HtmlInput { type="email"; placeholder="email"; required=true; minLength=3; maxLength=128 }
	Uri?	email

	@HtmlInput { type="text"; placeholder="password"; attributes="autocomplete=\"off\""; required=true; minLength=3; maxLength=128 }
	Str?	password

	RepoUser toUser() {
		RepoUser(email, password)
	}
}
