using afIoc
using afIocConfig
using afIocEnv
using afBedSheet
using afPillow
using afColdFeet

const class AuthenticationMiddleware : Middleware {
	
	@Inject private const HttpRequest 	httpRequest
	@Inject private const UserSession	userSession
	@Inject private const Backdoor		backdoor
	@Inject private const Pages			pages

	@Config { id="afColdFeet.urlPrefix" }
	@Inject private const Str			coldFeetPrefix 

	new make(|This|in) { in(this) }
	
	override Void service(MiddlewarePipeline pipeline)  {
		strUrl := httpRequest.url.toStr

		// let assets through - /scripts/ for require.js
		if (strUrl.startsWith(coldFeetPrefix) || strUrl.startsWith("/scripts/")) {
			pipeline.service; return
		}

		// non-user urls are ok
		if (!strUrl.startsWith("/my/")) {
			pipeline.service; return
		}
		
		// check the common scenario first - check authorisation
		if (userSession.isLoggedIn) {
			pipeline.service; return
		}
		
		// let users gate crash if they have a back stage pass
		// e.g. auto-login during dev
		if (backdoor.isOpen) {
			backdoor.login
			pipeline.service; return
		}

		throw ReProcessErr(Redirect.movedTemporarily(pages[LoginPage#].pageUrl))
	}
}
