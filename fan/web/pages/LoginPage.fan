using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afFormBean

const mixin LoginPage : PrPage {

	@Inject abstract RepoUserDao	userDao
	@Inject { type=LoginDetails# } 
			abstract FormBean		formBean
			abstract LoginDetails?	loginDetails

	@BeforeRender
	Void beforeRender() {
		loginDetails = LoginDetails()
		formBean.formFields[LoginDetails#password].formValue = ""
	}

	Str loginUrl() {
		pageMeta.eventUrl(#onLogin).encode
	}
	
	Str formCss() {
		formBean.hasErrors ? "form-error" : "form-okay"
	}

	@PageEvent { name=""; httpMethod="POST" }
	Obj? onLogin() {
		if (!formBean.validateForm(httpRequest.body.form))
			return null

		loginDetails = formBean.createBean
		if (loginDetails.isSpamBot)
			return HttpStatus(403, "SpamBots NOT allowed!")

		user := userDao.getByEmail(loginDetails.email, false)
		if (user == null) {
			formBean.errorMsgs.add(Msgs.login_userNotFound)
			return null			
		}
		if(user.generateSecret(loginDetails.password) != user.userSecret) {
			logActivity(LogMsgs.loginFailed, "${loginDetails.email} / ${loginDetails.password}")
			formBean.errorMsgs.add(Msgs.login_incorrectPassword)
			return null
		}
		
		userSession.loginAs(user)
		logUserActivity(LogMsgs.loggedIn)
		
		alert.success = Msgs.alert_userLoggedIn(user)
		return Redirect.afterPost(pages[MyPodsPage#].pageUrl)
	}
}

class LoginDetails {
	
	@HtmlInput { type="email"; placeholder="email"; required=true; minLength=3; maxLength=128 }
	Uri?	email

	@HtmlInput { type="password"; placeholder="password"; attributes="autocomplete=\"off\""; required=true; minLength=3; maxLength=128 }
	Str?	password

	@HtmlInput { type="honeyPot"; placeholder="password"; attributes="autocomplete=\"off\""; minLength=3; maxLength=128; hint="Leave blank" }
	Str?	passwordAgain
	
	Bool isSpamBot() {
		passwordAgain != null
	}
}
