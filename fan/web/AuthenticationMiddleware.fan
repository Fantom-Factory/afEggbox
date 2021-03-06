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

	new make(|This|in) { in(this) }
	
	override Void service(MiddlewarePipeline pipeline)  {
		strUrl := httpRequest.url.toStr

		if (strUrl.startsWith("/pods/") && httpRequest.url.path.size > 1) {
			pod := podDao.findPod(httpRequest.url.path[1])
			if (pod == null || pod.isPublic) {
				pipeline.service; return				
			}
			
			if (!userSession.isLoggedIn && backdoor.isOpen)
				backdoor.login

			if (userSession.isLoggedIn) {
				if (userSession.user.owns(pod)) {
					pipeline.service; return	
				}
				throw HttpStatus.makeErr(401, "Unauthorised")
			}

			throw HttpRedirect.movedTemporarilyErr(pages[LoginPage#].pageUrl)
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
			
			throw HttpRedirect.movedTemporarilyErr(pages[LoginPage#].pageUrl)
		}
		
		pipeline.service
	}
}
