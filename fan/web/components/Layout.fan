using afIoc
using afIocConfig
using afIocEnv
using afEfanXtra
using afBedSheet
using afPillow
using afDuvet

const mixin Layout : PrComponent {
	
	@Inject abstract PageMeta		pageMeta
	@Inject abstract HttpRequest	httpReq
	@Inject abstract IocEnv			iocEnv

	abstract Str? title
	abstract Str? pageId

	@Config { id="afIocEnv.isProd" }
	@Inject abstract Bool	inProd

	@InitRender
	Void init(Str title) {
		this.title 	= title
		this.pageId = pageMeta.pageType.name.decapitalize
		
		injector.injectStylesheet.fromLocalUrl(`/css/website.min.css`)
//		injector.injectScript.fromLocalUrl(`/js/bootstrap.min.js`)
		injector.injectRequireModule("bootstrap")
	}
	
	Str pageTitle() {
		"${title} :: Pod-Repo"
	}

	Str env() {
		"env${iocEnv.abbr.capitalize}"
	}	
}

