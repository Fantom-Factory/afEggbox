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
	HttpRedirect? onSave() {
		if (!formBean.validateForm(httpRequest.body.form))
			return null

		formBean.updateBean(user)
		
		existing := userDao.getByScreenName(user.screenName, false)
		if (existing != null && existing._id != loggedInUser._id) {
			formBean.errorMsgs.add(Msgs.userEdit_screenNameTaken(user.screenName))
			return null
		}
		
		if (user.gravatarEmail != null && user.gravatarEmail != loggedInUser.gravatarEmail)
			if ((user.aboutMe?.trimToNull == null && user.aboutMe?.trimToNull == null) || (user.realName?.trimToNull == null && user.realName?.trimToNull == null))
				user.populateFromGravatar
		
		userDao.update(user)
		logUserActivity(LogMsgs.updatedUser)
		
		alert.success = Msgs.alert_userDetailsSaved(user)
		return HttpRedirect.afterPost(pages[MyDetailsPage#].pageUrl)
	}
}
