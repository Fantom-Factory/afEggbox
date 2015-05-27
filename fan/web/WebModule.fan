using afIoc
using afIocConfig
using afIocEnv
using afBedSheet
using afDuvet
using afFormBean::InputSkins
using afFormBean::ErrorSkin
using afGoogleAnalytics::GoogleAnalyticsConfigIds

@SubModule { modules=[BedFrameModule#, FandocModule#] }
class WebModule {
	
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(Alert#)
		defs.add(ErrorSkin#, BootstrapErrorSkin#)
		defs.add(Backdoor#)
	}

	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(Configuration config) {
		config.add(config.autobuild(PodRoutes#))
	}
	
	@Contribute { serviceType=InputSkins# }
	static Void contributeInputSkins(Configuration config) {
		config.overrideValue("email",		BootstrapTextSkin())
		config.overrideValue("text",		BootstrapTextSkin())
		config.overrideValue("url",			BootstrapTextSkin())
		config.overrideValue("password",	BootstrapTextSkin())
		config.overrideValue("checkbox",	BootstrapCheckboxSkin())
		config.overrideValue("textarea",	BootstrapTextAreaSkin())
		config.set			("static",		BootstrapStaticSkin())
	}
	
	@Contribute { serviceType=MiddlewarePipeline# }
	static Void contributeBedSheetMiddleware(Configuration config) {
		config.set("AuthMiddleware", config.autobuild(AuthenticationMiddleware#)).before("afBedSheet.routes")
	}

	@Contribute { serviceType=ValueEncoders# }
	static Void contributeValueEncoders(Configuration config) {
		config[RepoPod#]	= config.autobuild(PodValueEncoder#)
		config[RepoUser#]	= config.autobuild(UserValueEncoder#)
		config[FandocUri#]	= config.autobuild(FandocUriValueEncoder#)
	}
	
	@Contribute { serviceType=ScriptModules# }
	static Void contributeScriptModules(Configuration config) {
		config.add(ScriptModule("jquery"		).atUrl(`//code.jquery.com/jquery-1.11.2.min.js`).fallbackToUrl(`/js/jquery-1.11.2.min.js`))
		config.add(ScriptModule("bootstrap"		).atUrl(`/js/bootstrap.min.js`).requires("jquery"))
		config.add(ScriptModule("podRepoModules").atUrl(`/js/podRepoModules.js`))
	}
	
	@Contribute { serviceType=RequireJsConfigTweaks# }
	static Void contributeRequireJsConfigTweaks(Configuration conf) {
		conf["app.bundles"] = |Str:Obj? config| {
			bundles := (Str:Str[]) config.getOrAdd("bundles") { [Str:Str[]][:] }
			bundles["podRepoModules"] = "fileInput".split
		}
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
	static Void contributeApplicationDefaults(Configuration config, PodRepoConfig repoConfig, IocEnv iocEnv) {
		
		config[BedSheetConfigIds.host]					= repoConfig.publicUrl
		config[GoogleAnalyticsConfigIds.accountNumber]	= repoConfig.googleAccNo
		config[GoogleAnalyticsConfigIds.accountDomain]	= repoConfig.googleAccDomain
		
		config[BedSheetConfigIds.fileAssetCacheControl]	= "max-age=${1day.toSec}"	// it's better than nothing!
		
		config[DuvetConfigIds.requireJsTimeout]			= 8sec
	}
}
