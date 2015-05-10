using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afFormBean

const mixin SignupPage : PrPage {

	@Inject abstract RepoUserDao	userDao
//	@Inject	abstract SystemActivity	systemActivity
//	@Inject abstract UserActivity	userActivity
//	@Inject	abstract FlashMsg		flash
	@Inject { type=SignUpDetails# } 
			abstract FormBean		formBean
			abstract SignUpDetails?	signUpDetails

	@BeforeRender
	Void initRender() {
		signUpDetails = SignUpDetails()
		formBean.formFields[SignUpDetails#password].formValue = ""
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

		user = userDao.create(signUpDetails.toUser)
		userSession.loginAs(user)
//		userActivity.logLoggedIn
		
		alert.msg = Msgs.alert_userSignedUp(user)
		return Redirect.afterPost(pages[MyDetailsPage#].pageUrl)
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
