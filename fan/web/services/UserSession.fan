using afIoc
using afConcurrent
using afBedSheet

const class UserSession {
	@Inject private const RepoUserDao 	userDao
	@Inject private const HttpSession 	httpSession
	@Inject private const LocalRef 		userRef
	
	private UserSessionState? sessionState {
		get { httpSession[UserSession#.qname] }
		set { httpSession[UserSession#.qname] = it }
	}
	
	new make(|This|in) { in(this) }

	Bool isLoggedIn() {
		sessionState?.email != null 
	}

	Void loginAs(RepoUser user) {
		sessionState = UserSessionState { it.email = user.email }
	}
	
	RepoUser? logout() {
		user := user
		httpSession.remove(UserSession#.qname)
		userRef.cleanUp
		return user
	}
	
	RepoUser? user() {
		if (isLoggedIn && !userRef.isMapped)
			userRef.val = userDao[sessionState.email]
		return userRef.val
	}
}

@Serializable
class UserSessionState {
	Uri? email
}