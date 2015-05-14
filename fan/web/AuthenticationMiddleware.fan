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
	@Inject	private const RepoPodDao	podDao

	@Config { id="afColdFeet.urlPrefix" }
	@Inject private const Str			coldFeetPrefix 

	new make(|This|in) { in(this) }
	
	override Void service(MiddlewarePipeline pipeline)  {
		strUrl := httpRequest.url.toStr

		if (strUrl.startsWith("/pods/") && httpRequest.url.path.size > 1) {
			pod := podDao.findOne(httpRequest.url.path[1])
			if (pod.isPublic) {
				pipeline.service; return				
			}
			
			if (userSession.isLoggedIn && userSession.user.owns(pod)) {
				pipeline.service; return								
			}

			throw ReProcessErr(Redirect.movedTemporarily(pages[LoginPage#].pageUrl))
		}

		if (strUrl.startsWith("/my/")) {
			// check the common scenario first - user is logged in
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
		
		pipeline.service
	}
}
