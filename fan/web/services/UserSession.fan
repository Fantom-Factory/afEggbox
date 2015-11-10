using afIoc
using afConcurrent
using concurrent
using afBedSheet

const class UserSession {
	@Inject private const RepoUserDao 	userDao
	@Inject private const HttpSession 	httpSession
	@Inject private const LocalRef 		requestUserRef
	
	private UserSessionState? sessionState {
		get { httpSession[UserSession#.qname] }
		set { httpSession[UserSession#.qname] = it }
	}
	
	new make(|This|in) { in(this) }

	Bool isLoggedIn() {
		(requestUserRef.isMapped && requestUserRef.val != null) || (inWebReq && sessionState?.email != null) 
	}

	Void loginRequestAs(RepoUser user) {
		requestUserRef.val = user
	}

	Void loginAs(RepoUser user) {
		sessionState = UserSessionState { it.email = user.email }
	}
	
	RepoUser? logout() {
		user := user
		requestUserRef.cleanUp
		if (inWebReq)
			httpSession.remove(UserSession#.qname)
		return user
	}
	
	RepoUser? user() {
		if (isLoggedIn) {
			if (requestUserRef.isMapped)
				return requestUserRef.val
			if (inWebReq)
				return userDao.getByEmail(sessionState.email)
			throw Err("WTF")
		}
		return null
	}
	
	private Bool inWebReq() {
		Actor.locals.containsKey("web.req")
	}
}

@Serializable
const class UserSessionState {
	const Uri? email
	
	new make(|This|in) { in(this) }
}
