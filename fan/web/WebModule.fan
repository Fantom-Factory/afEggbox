using afIoc
using afIocConfig
using afIocEnv
using afBedSheet
using afDuvet
using afFormBean::InputSkins
using afFormBean::ErrorSkin

@SubModule { modules=[BedFrameModule#] }
class WebModule {
	
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(ErrorSkin#, BootstrapErrorSkin#)
		defs.add(Backdoor#)
	}

	@Contribute { serviceType=InputSkins# }
	static Void contributeInputSkins(Configuration config) {
		config.overrideValue("email",		BootstrapInputSkin())
		config.overrideValue("text",		BootstrapInputSkin())
		config.overrideValue("password",	BootstrapInputSkin())
	}
	
	@Contribute { serviceType=MiddlewarePipeline# }
	static Void contributeBedSheetMiddleware(Configuration config) {
		config.set("AuthMiddleware", config.autobuild(AuthenticationMiddleware#)).before("afBedSheet.routes")
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
	
	@Contribute { serviceType=ApplicationDefaults# }
	static Void contributeApplicationDefaults(Configuration config, IocEnv iocEnv) {
//		if (iocEnv.isProd)
//			config[BedSheetConfigIds.host]				= "http://www.fantomfactory.org"
//		config[GoogleAnalyticsConfigIds.accountNumber]	= "UA-33997125-4"
//		config[GoogleAnalyticsConfigIds.accountDomain]	= "//fantomfactory.org"
		
		config[BedSheetConfigIds.fileAssetCacheControl]	= "max-age=${1day.toSec}"	// it's better than nothing!
		
		config[DuvetConfigIds.requireJsTimeout]			= 8sec
	}
}
