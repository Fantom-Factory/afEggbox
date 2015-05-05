using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afFormBean

const mixin SignupPage : PrPage {

	@Inject abstract RepoUserDao	userDao
	@Inject abstract UserSession	userSession
//	@Inject	abstract SystemActivity	systemActivity
//	@Inject abstract UserActivity	userActivity
//	@Inject	abstract FlashMsg		flash
	@Inject { type=SignUpDetails# } 
			abstract FormBean		formBean
			abstract SignUpDetails?	signUpDetails

	@InitRender
	Void initRender() {
		signUpDetails = SignUpDetails()
		formBean.messages["field.submit.label"] = "Sign Up"
	}

	Str signUpUrl() {
		pageMeta.eventUrl(#onSignUp).encode
	}

	@PageEvent { name=""; httpMethod="POST" }
	Redirect? onSignUp() {
		if (!formBean.validateForm(httpRequest.body.form))
			return null

		signUpDetails = formBean.createBean
		
		user := userDao.findByEmail(signUpDetails.email)
		if (user != null) {
//			systemActivity.logFailedLogin(loginDetails.email, loginDetails.password)
			formBean.errorMsgs.add(Msgs.signup_emailTaken(user.email))
			return null
		}

		user = userDao.create(signUpDetails.toUser)
		userSession.loginAs(user)
//		userActivity.logLoggedIn
		return Redirect.afterPost(pages[MyDetailsPage#].pageUrl)
	}
}

class SignUpDetails {
	
	@HtmlInput { type="email"; required=true; minLength=3; maxLength=128 }
	Uri?	email

	@HtmlInput { type="password"; required=true; minLength=3; maxLength=128 }
	Str?	password

	RepoUser toUser() {
		RepoUser(email, password)
	}
}
