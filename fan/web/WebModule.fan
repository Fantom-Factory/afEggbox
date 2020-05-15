using afIoc
using afIocConfig
using afIocEnv
using afBedSheet
using afDuvet
using afPillow
using afEfanXtra::TemplateConverters
using afFormBean::InputSkins
using afFormBean::ErrorSkin
using afGoogleAnalytics

@SubModule { modules=[BedFrameModule#, FandocModule#] }
const class WebModule {

	Void defineServices(RegistryBuilder defs) {
		defs.addService(Alert#)
		defs.addService(ErrorSkin#, BootstrapErrorSkin#)
		defs.addService(Backdoor#)
		defs.addService(SitemapPages#)
		defs.addService(AtomFeedPages#)
		defs.addService(AtomFeedGenerator#)
		
		defs.decorateService("afPillow::Pages") |Configuration config| {
			config["dirtyCash"] = |Obj? pages, Scope scope->Obj?| {
				scope.build(DirtyPages#, [pages])
			}
		}
	}

	@Contribute { serviceType=Routes# }
	Void contributeRoutes(Configuration config) {
		config.add(Route(`/pods/**`, PodPageResponse(), "GET POST"))
	}
	
	@Contribute { serviceType=ResponseProcessors# }
	Void contributeResponseProcessors(Configuration config) {
		config[PodPageResponse#]	= config.build(PodPageProcessor#)
	}
	
	@Contribute { serviceType=HttpStatusResponses# }
	Void contribute404Response(Configuration config) {
		config[404] = MethodCall(Pages#renderPage, [Error404Page#]).toImmutableFunc
	}

	@Contribute { serviceType=InputSkins# }
	Void contributeInputSkins(Configuration config) {
		config.overrideValue("email",		BootstrapTextSkin())
		config.overrideValue("text",		BootstrapTextSkin())
		config.overrideValue("url",			BootstrapTextSkin())
		config.overrideValue("password",	BootstrapTextSkin())
		config.overrideValue("checkbox",	BootstrapCheckboxSkin())
		config.overrideValue("textarea",	BootstrapTextAreaSkin())
		config.overrideValue("select",		config.build(BootstrapSelectSkin#))
		config.set			("static",		BootstrapStaticSkin())
		config.set			("honeyPot",	BootstrapHoneyPotSkin())
	}
	
	@Contribute { serviceType=MiddlewarePipeline# }
	Void contributeBedSheetMiddleware(Configuration config) {
		// needed for Google WebMaster Tools to accept a change of domain
		//config.set("DomainFilter", config.autobuild(DomainFilter#)).before("AuthMiddleware")
		config.set("AuthMiddleware", config.build(AuthenticationMiddleware#)).before("afBedSheet.routes")
	}

	@Contribute { serviceType=ClientAssetProducers# }
	Void contributeAssetProducers(Configuration config) {
		config["podAssetProducer"] = config.build(PodAssetProducer#)
	}

	@Contribute { serviceType=ValueEncoders# }
	Void contributeValueEncoders(Configuration config) {
		config[RepoPod#]	= config.build(PodValueEncoder#)
		config[RepoUser#]	= config.build(UserValueEncoder#)
		config[FandocUri#]	= config.build(FandocUriValueEncoder#)
	}
	
	@Contribute { serviceType=ScriptModules# }
	Void contributeScriptModules(Configuration config, FileHandler fh) {
		// Internet explorer doesn't like CDN URLs starting with // so http:// is used 
		config.add(ScriptModule("jquery"		).atUrl(`http://code.jquery.com/jquery-1.11.2.min.js`).fallbackToUrl(fh.fromLocalUrl(`/js/jquery-1.11.2.min.js`).clientUrl))
		config.add(ScriptModule("bootstrap"		).atUrl(fh.fromLocalUrl(`/js/bootstrap.min.js`).clientUrl).requires("jquery"))
		config.add(ScriptModule("eggboxModules"	).atUrl(fh.fromLocalUrl(`/js/eggboxModules.js`).clientUrl))
		config.add(ScriptModule("d3"			).atUrl(fh.fromLocalUrl(`/js/d3.min.js`).clientUrl).exports("d3"))
	}
	
	@Contribute { serviceType=RequireJsConfigTweaks# }
	Void contributeRequireJsConfigTweaks(Configuration conf) {
		conf["app.bundles"] = |Str:Obj? config| {
			bundles := (Str:Str[]) config.getOrAdd("bundles") { [Str:Str[]][:] }
			bundles["eggboxModules"] = "onReveal podGraph fileInput unscramble rowLink anchorJS tinysort podFiltering podSearch tableSort debounce notFound hiveSparks".split
		}
	}
	
	@Contribute { serviceType=TemplateConverters# }
	internal Void contributeTemplateConverters(Configuration config) {
		config.remove("fandoc")	// so we can have help fandoc file named after the class
	}

	@Contribute { serviceType=ApplicationDefaults# }
	Void contributeApplicationDefaults(Configuration config, EggboxConfig eggboxConfig, IocEnv iocEnv) {
		
		if (eggboxConfig.publicUrl != null)
			config[BedSheetConfigIds.host]					= eggboxConfig.publicUrl
		if (eggboxConfig.googleAccNo != null)
			config[GoogleAnalyticsConfigIds.accountNumber]	= eggboxConfig.googleAccNo
		if (eggboxConfig.googleAccDomain != null)
			config[GoogleAnalyticsConfigIds.accountDomain]	= eggboxConfig.googleAccDomain
		
		config[BedSheetConfigIds.fileAssetCacheControl]		= "max-age=${1day.toSec}"	// it's better than nothing!
		
		config[DuvetConfigIds.requireJsTimeout]				= 8sec
		
		config["afEggbox.aboutFandocExists"]				= `about.fandoc`.toFile.exists
	}
}

const class DirtyPages : Pages {
	
	@Inject
	private const DirtyCash	dirtyCash
	private const Pages 	pages

	new make(Pages pages, |This|in) {
		in(this)
		this.pages = pages
	}
	
	override Type[] pageTypes() {
		pages.pageTypes
	}

	override PageMeta pageMeta(Type pageType, Obj[]? pageContext := null) {
		pages.pageMeta(pageType, pageContext)
	}

	override PageMeta get(Type pageType, Obj[]? pageContext := null) {
		pages.get(pageType, pageContext)
	}

	override Obj renderPage(Type pageType, Obj[]? pageContext := null) {
		return dirtyCash.cash |->Obj?| { 
			pages.renderPage(pageType, pageContext)
		}
	}

	override Obj renderPageMeta(PageMeta pageMeta) {
		pages.renderPageMeta(pageMeta)
	}

	override Obj callPageEvent(Type pageType, Obj[]? pageContext, Method eventMethod, Obj[]? eventContext) {
		pages.callPageEvent(pageType, pageContext, eventMethod, eventContext)
	}
}