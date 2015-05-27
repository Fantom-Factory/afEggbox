using afIoc
using afIocConfig
using afIocEnv
using afEfanXtra
using afBedSheet
using afPillow
using afDuvet

const mixin Layout : PrComponent {
	
	@Inject abstract HttpRequest	httpReq
	@Inject abstract IocEnv			iocEnv
	@Inject	abstract Alert			alert
	@Inject	abstract PodRepoConfig	repoConfig
	@Inject	abstract EfanXtra		efanXtra

	abstract Str? title
	abstract Str? pageId

	@Config { id="afIocEnv.isProd" }
	@Inject abstract Bool	inProd

	@InitRender
	Void init(Str title) {
		this.title 	= title
		this.pageId = pageMeta.pageType.name.decapitalize
		
		injector.injectStylesheet.fromLocalUrl(`/css/website.min.css`)
		injector.injectRequireModule("bootstrap")
	}
	
	Str pageTitle() {
		"${title} :: Pod-Repo"
	}

	Str env() {
		"env${iocEnv.abbr.capitalize}"
	}
	
	Bool googleAnalyticsEnabled() {
		if (!repoConfig.googleAnalyticsEnabled)
			return false

		// FIXME: how to tell if a page is public or private?
		
		return false
	}
}

