using afIoc
using afBedSheet
using afFormBean
using afEfanXtra
using afPillow

const mixin MyDetailsPage : PrMyPage {
	
	@Inject abstract RepoUserDao	userDao
	@Inject { type=RepoUser# } 
			abstract FormBean		formBean

	Str saveUrl() {
		pageMeta.eventUrl(#onSave).encode
	}
	
	@PageEvent { httpMethod="POST" }
	Redirect? onSave() {
		if (!formBean.validateForm(httpRequest.body.form))
			return null

		formBean.updateBean(user)
		userDao.update(user)

		alert.msg = Msgs.alert_userDetailsSaved(user)
		return Redirect.afterPost(pages[MyDetailsPage#].pageUrl)
	}
}
