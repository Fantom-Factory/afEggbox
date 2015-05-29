using afIoc
using afBedSheet
using afFormBean
using afEfanXtra
using afPillow
using afSitemap

const mixin MyDetailsPage : PrMyPage, SitemapExempt {
	
	@Inject abstract RepoUserDao	userDao
	@Inject { type=RepoUser# } 
			abstract FormBean		formBean
			abstract RepoUser		user

	@InitRender
	Void initRender() {
		user = userDao.get(loggedInUser._id)
	}
	
	Str saveUrl() {
		pageMeta.eventUrl(#onSave).encode
	}
	
	@PageEvent { httpMethod="POST" }
	Redirect? onSave() {
		if (!formBean.validateForm(httpRequest.body.form))
			return null

		formBean.updateBean(loggedInUser)
		
		existing := userDao.getByScreenName(user.screenName, false)
		if (existing != null && existing._id != loggedInUser._id) {
			formBean.errorMsgs.add(Msgs.userEdit_screenNameTaken(user.screenName))
			return null
		}
		
		userDao.update(loggedInUser)

		alert.msg = Msgs.alert_userDetailsSaved(loggedInUser)
		return Redirect.afterPost(pages[MyDetailsPage#].pageUrl)
	}
}
