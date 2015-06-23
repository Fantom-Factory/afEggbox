using afIoc
using afIocEnv
using afBedSheet
using afPillow

const class Backdoor {	
	@Inject private const Log			log
	@Inject private const EggboxConfig	eggboxConfig
	@Inject private const RepoUserDao	userDao
	@Inject private const UserSession	userSession
	@Inject private const Alert			alert
	@Inject private const Pages			pages
	@Inject	private const HttpSession	httpSession

	new make(|This|in) { in(this) }
	
	Bool isOpen() {
		eggboxConfig.autoLoginEnabled
	}
	
	Void login() {
		user := userDao.getByEmail(eggboxConfig.autoLoginEmail, false)
		if (user == null) {
			alert.error = "Auto login user `${eggboxConfig.autoLoginEmail}` has not been created. Why not do it now?"
			httpSession.flash["signUp.email"] = eggboxConfig.autoLoginEmail
			throw ReProcessErr(Redirect.movedTemporarily(pages[SignupPage#].pageUrl))
		}
		log.warn("Auto Logging in `${eggboxConfig.autoLoginEmail}` via backdoor...")
		userSession.loginAs(user)
	}
}