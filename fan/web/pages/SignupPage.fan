using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afFormBean

const mixin SignupPage : PrPage {

	@Inject abstract Registry		registry
	@Inject abstract RepoUserDao	userDao
	@Inject	abstract HttpSession	httpSession
	@Inject { type=SignUpDetails# } 
			abstract FormBean		formBean
			abstract SignUpDetails?	signUpDetails

	@BeforeRender
	Void beforeRender() {
		signUpDetails = SignUpDetails()
		formBean.formFields[SignUpDetails#password].formValue = ""
		
		if (httpSession.flashExists && httpSession.flash["signUp.email"] != null)
			signUpDetails.email = httpSession.flash["signUp.email"]
	}

	Str signUpUrl() {
		pageMeta.eventUrl(#onSignUp).encode
	}
	
	Str formCss() {
		formBean.hasErrors ? "form-error" : "form-okay"
	}

	@PageEvent { name=""; httpMethod="POST" }
	Obj? onSignUp() {
		if (!formBean.validateForm(httpRequest.body.form))
			return null

		signUpDetails = formBean.createBean
		if (signUpDetails.isSpamBot)
			return HttpStatus(403, "SpamBots NOT allowed!")
	
		existing := userDao.getByEmail(signUpDetails.email, false)
		if (existing != null) {
			formBean.errorMsgs.add(Msgs.signup_emailTaken(existing.email))
			return null
		}
		
		user := signUpDetails.toUser
		orig := user.screenName
		while (userDao.getByScreenName(user.screenName, false) != null) {
			user.screenName = orig + " " + Int.random(0..9999).toStr
		}

		registry.injectIntoFields(user)
		user.populateFromGravatar
		userDao.create(user)
		userSession.loginAs(user)
		logUserActivity(LogMsgs.signedUp)
		
		alert.success = Msgs.alert_userSignedUp(user)
		return Redirect.afterPost(pages[UsersPage#].withContext([user.screenName]).pageUrl)
	}
}

class SignUpDetails {
	
	@HtmlInput { type="email"; placeholder="email"; required=true; minLength=3; maxLength=128 }
	Uri?	email

	@HtmlInput { type="password"; placeholder="password"; attributes="autocomplete=\"off\""; required=true; minLength=3; maxLength=128 }
	Str?	password

	@HtmlInput { type="honeyPot"; placeholder="password"; attributes="autocomplete=\"off\""; minLength=3; maxLength=128; hint="Leave blank" }
	Str?	passwordAgain

	RepoUser toUser() {
		RepoUser(email, password)
	}

	Bool isSpamBot() {
		passwordAgain != null && passwordAgain.size > 0
	}
}
