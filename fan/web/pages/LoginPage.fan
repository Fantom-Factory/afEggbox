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
	Void initRender() {
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
	Redirect? onLogin() {
		if (!formBean.validateForm(httpRequest.body.form))
			return null

		loginDetails = formBean.createBean
		
		user := userDao.getByEmail(loginDetails.email, false)
		if (user == null) {
			formBean.errorMsgs.add(Msgs.login_userNotFound)
			return null			
		}
		if(user.generateSecret(loginDetails.password) != user.userSecret) {
//			systemActivity.logFailedLogin(loginDetails.email, loginDetails.password)
			formBean.errorMsgs.add(Msgs.login_incorrectPassword)
			return null
		}
		
		userSession.loginAs(user)
//		userActivity.logLoggedIn
		
		alert.msg = Msgs.alert_userLoggedIn(user)
		return Redirect.afterPost(pages[MyPodsPage#].pageUrl)
	}
}

class LoginDetails {
	
	@HtmlInput { type="email"; placeholder="email"; required=true; minLength=3; maxLength=128 }
	Uri?	email

	@HtmlInput { type="text"; placeholder="password"; attributes="autocomplete=\"off\""; required=true; minLength=3; maxLength=128 }
	Str?	password
}
