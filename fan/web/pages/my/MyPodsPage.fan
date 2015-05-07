using afIoc
using afBedSheet
using afFormBean
using afEfanXtra
using afPillow

const mixin MyPodsPage : PrMyPage {
	
	@Inject abstract MongoRepo		mongoRepo
	@Inject abstract RepoPodDao		podDao
	//	@Inject	abstract SystemActivity	systemActivity
//	@Inject abstract UserActivity	userActivity
//	@Inject	abstract FlashMsg		flash
	@Inject { type=LoginDetails# } 
			abstract FormBean		formBean
			abstract RepoPod[]		allPods

	@InitRender
	Void initRender() {
		allPods = podDao.findAll
		injector.injectRequireModule("fileInput")
	}
	
	Str downloads(Obj o) {
		""
	}
	
	Str uploadUrl() {
		pageMeta.eventUrl(#onUpload).encode
	}

	@PageEvent { httpMethod="POST" }
	Redirect? onUpload() {
		try {
	        httpRequest.parseMultiPartForm |Str inputName, InStream in, Str:Str headers| {
				if (inputName == "podFile")
					mongoRepo.publish(userSession.user, in)
	        }
//			userActivity.logLoggedIn
			return Redirect.afterPost(pages[MyPodsPage#].pageUrl)

		} catch (Err err) {
			formBean.errorMsgs.add(err.msg)
			return null
		}
	}
}
