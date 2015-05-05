using afIoc
using afIocEnv

const class Backdoor {	
	@Inject private const Log			log
	@Inject private const IocEnv		env
	@Inject private const RepoUserDao	userDao
	@Inject private const UserSession	userSession

	new make(|This|in) { in(this) }
	
	Bool isOpen() {
		env.isDev
	}
	
	Void login() {
		user := userDao.get(`backdoor@testing.com`, false)
		if (user == null)
			user = userDao.create(RepoUser(`backdoor@testing.com`, "password"))
		log.warn("Logging user in via backdoor...")
		userSession.loginAs(user)
	}
}