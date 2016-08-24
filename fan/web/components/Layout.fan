using afIoc
using afIocConfig
using afIocEnv
using afEfanXtra
using afBedSheet
using afPillow
using afDuvet
using afGoogleAnalytics::GoogleAnalytics

const mixin Layout : PrComponent {
	
	@Inject abstract HttpRequest		httpReq
	@Inject abstract IocEnv				iocEnv
	@Inject	abstract Alert				alert
	@Inject	abstract EggboxConfig		eggboxConfig
	@Inject	abstract EfanXtra			efanXtra
	@Inject	abstract GoogleAnalytics	googleAnalytics

	abstract Str? title
	abstract Str? pageId
	abstract Bool isPublic

	@Config { id="afIocEnv.isProd" }
	@Inject abstract Bool	inProd

	@InitRender
	Void init(Bool isPublic, Str title) {
		this.isPublic	= isPublic
		this.title 		= title
		this.pageId 	= pageMeta.pageType.name.decapitalize
		
		injector.injectStylesheet.fromLocalUrl(`/css/website.min.css`)
		injector.injectRequireModule("bootstrap")
		injector.injectRequireModule("hiveSparks")
	}
	
	@AfterRender
	Void afterRender() {
		if (googleAnalyticsEnabled && !googleAnalytics.pageViewRendered)
			googleAnalytics.sendPageView		
	}

	Str pageTitle() {
		title
	}

	Str env() {
		"env${iocEnv.abbr.capitalize}"
	}
	
	Bool googleAnalyticsEnabled() {
		eggboxConfig.googleAnalyticsEnabled ? isPublic : false
	}
	
	Bool isIndexPage() {
		pageMeta.pageType == IndexPage#
	}
}
