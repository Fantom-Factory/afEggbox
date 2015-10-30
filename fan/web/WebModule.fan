using afIoc
using afIocConfig
using afIocEnv
using afBedSheet
using afDuvet
using afPillow
using afEfanXtra::TemplateConverters
using afFormBean::InputSkins
using afFormBean::ErrorSkin

@SubModule { modules=[BedFrameModule#, FandocModule#, GoogleAnalyticsModule#] }
class WebModule {

	static Void defineServices(ServiceDefinitions defs) {
		defs.add(Alert#)
		defs.add(ErrorSkin#, BootstrapErrorSkin#)
		defs.add(Backdoor#)
		defs.add(SitemapPages#)
		defs.add(AtomFeedPages#)
		defs.add(AtomFeedGenerator#)
	}

	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(Configuration config) {
		config.add(config.autobuild(PodRoutes#))
	}
	
	@Contribute { serviceType=HttpStatusResponses# }
	static Void contribute404Response(Configuration config) {
		config[404] = MethodCall(Pages#renderPage, [Error404Page#]).toImmutableFunc
	}

	@Contribute { serviceType=InputSkins# }
	static Void contributeInputSkins(Configuration config) {
		config.overrideValue("email",		BootstrapTextSkin())
		config.overrideValue("text",		BootstrapTextSkin())
		config.overrideValue("url",			BootstrapTextSkin())
		config.overrideValue("password",	BootstrapTextSkin())
		config.overrideValue("checkbox",	BootstrapCheckboxSkin())
		config.overrideValue("textarea",	BootstrapTextAreaSkin())
		config.overrideValue("select",		config.autobuild(BootstrapSelectSkin#))
		config.set			("static",		BootstrapStaticSkin())
		config.set			("honeyPot",	BootstrapHoneyPotSkin())
	}
	
	@Contribute { serviceType=MiddlewarePipeline# }
	static Void contributeBedSheetMiddleware(Configuration config) {
		config.set("AuthMiddleware", config.autobuild(AuthenticationMiddleware#)).before("afBedSheet.routes")
	}

	@Contribute { serviceType=ClientAssetProducers# }
	static Void contributeAssetProducers(Configuration config) {
		config["podAssetProducer"] = config.autobuild(PodAssetProducer#)
	}

	@Contribute { serviceType=ValueEncoders# }
	static Void contributeValueEncoders(Configuration config) {
		config[RepoPod#]	= config.autobuild(PodValueEncoder#)
		config[RepoUser#]	= config.autobuild(UserValueEncoder#)
		config[FandocUri#]	= config.autobuild(FandocUriValueEncoder#)
	}
	
	@Contribute { serviceType=ScriptModules# }
	static Void contributeScriptModules(Configuration config, FileHandler fh) {
		config.add(ScriptModule("jquery"		).atUrl(`//code.jquery.com/jquery-1.11.2.min.js`).fallbackToUrl(fh.fromLocalUrl(`/js/jquery-1.11.2.min.js`).clientUrl))
		config.add(ScriptModule("bootstrap"		).atUrl(fh.fromLocalUrl(`/js/bootstrap.min.js`).clientUrl).requires("jquery"))
		config.add(ScriptModule("eggboxModules"	).atUrl(fh.fromLocalUrl(`/js/eggboxModules.js`).clientUrl))
	}
	
	@Contribute { serviceType=RequireJsConfigTweaks# }
	static Void contributeRequireJsConfigTweaks(Configuration conf) {
		conf["app.bundles"] = |Str:Obj? config| {
			bundles := (Str:Str[]) config.getOrAdd("bundles") { [Str:Str[]][:] }
			bundles["eggboxModules"] = "fileInput unscramble rowLink anchorJS tinysort podFiltering tableSort notFound".split
		}
	}
	
	@Contribute { serviceType=TemplateConverters# }
	internal static Void contributeTemplateConverters(Configuration config) {
		config.remove("fandoc")	// so we can have help fandoc file named after the class
	}

	@Advise { serviceId="afPillow::Pages" }
	static Void addTransations(MethodAdvisor[] methodAdvisors, DirtyCash dirtyCash) {
		methodAdvisors
			.find { it.method.name.startsWith("renderPage") }
			.addAdvice |invocation -> Obj?| { 
				return dirtyCash.cash |->Obj?| { 
					return invocation.invoke
				}
			} 
	}
	
	@Contribute { serviceType=ApplicationDefaults# }
	static Void contributeApplicationDefaults(Configuration config, EggboxConfig eggboxConfig, IocEnv iocEnv) {
		
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
