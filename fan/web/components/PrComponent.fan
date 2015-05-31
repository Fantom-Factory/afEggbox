using afIoc::Inject
using afPillow::Pages
using afPillow::PageMeta
using afEfanXtra::Abstract
using afEfanXtra::EfanComponent
using afDuvet::HtmlInjector
using afBedSheet::HttpRequest
using afBedSheet::FileHandler

@Abstract
const mixin PrComponent : EfanComponent {

	@Inject	abstract Pages	 			pages
	@Inject abstract HtmlInjector		injector
	@Inject abstract HttpRequest		httpRequest
	@Inject	abstract FileHandler		fileHandler
	@Inject	abstract PageMeta			pageMeta
	@Inject	abstract UserSession		userSession
	@Inject	abstract LinkResolvers		linkResolvers
	@Inject	abstract RepoActivityDao	activityDao
	
//	Str assetUrl(Uri localUrl) {
//		fileHandler.fromLocalUrl(localUrl).clientUrl.encode 
//	}

	Str pageUrl(Type pageType, Obj?[]? pageCtx := null) {
		pages[pageType].withContext(pageCtx).pageUrl.encode
	}

	Str userUrl(RepoUser user) {
		pageUrl(UsersPage#, [user])
	}
	
	** TODO: we could make this a contributable service
	** this is great, because you can't add format methods to Dates and other objs outside of your control
	Obj format(Obj? obj, Str hint := Str.defVal) {
		hints := hint.lower.split.exclude { it.isEmpty }
		
		if (obj == null) {
			return "???"
		}

		if (obj is DateTime) {
			date := (DateTime) obj
			return date.toLocale("DDD MMM YYYY")
		}

		throw ArgErr("WTF is a ${obj.typeof}??? Hints: ${hints} - $obj")
	}
	
	Void logActivity(Str what, Str? detail := null) {
		activityDao.create(RepoActivity(what, detail))
	}

	Void logUserActivity(Str what, Str? detail := null) {
		activityDao.create(RepoActivity(loggedInUser, what, detail))
	}

	Void logUserPodActivity(RepoPod pod, Str what, Str? detail := null) {
		activityDao.create(RepoActivity(loggedInUser, pod, what, detail))
	}
	
	Bool loggedIn() {
		userSession.isLoggedIn
	}

	RepoUser? loggedInUser() {
		userSession.user
	}
}
