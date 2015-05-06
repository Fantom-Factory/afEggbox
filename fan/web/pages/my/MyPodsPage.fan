using afIoc
using afBedSheet
using afFormBean
using afPillow

const mixin MyPodsPage : PrMyPage {
	
	@Inject abstract MongoRepo		mongoRepo
//	@Inject	abstract SystemActivity	systemActivity
//	@Inject abstract UserActivity	userActivity
//	@Inject	abstract FlashMsg		flash
	
	RepoPod[] allPods() {
		[,]
	}
	
	Str downloads(Obj o) {
		""
	}
	
	Str uploadUrl() {
		pageMeta.eventUrl(#onUpload).encode
	}

	@PageEvent { httpMethod="POST" }
	Redirect? onUpload() {
        httpRequest.parseMultiPartForm |Str formName, InStream in, Str:Str headers| {
			mongoRepo.publish(userSession.user, in)			
        }

//		user := userDao.findByEmail(podDetails.email)
//		if (user == null || user.generateSecret(loginDetails.password) != user.userSecret) {
////			systemActivity.logFailedLogin(loginDetails.email, loginDetails.password)
//			formBean.errorMsgs.add(Msgs.login_incorrectDetails)
//			return null
//		}

//		userActivity.logLoggedIn
		return Redirect.afterPost(pages[MyPodsPage#].pageUrl)
	}
}
