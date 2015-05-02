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
	
	Void logout() {
		httpSession.remove(UserSession#.qname)
		userRef.cleanUp
	}
	
	RepoUser? user() {
		if (!userRef.isMapped)
			userRef.val = userDao[sessionState.email]
		return userRef.val
	}
}

@Serializable
class UserSessionState {
	Uri? email
}