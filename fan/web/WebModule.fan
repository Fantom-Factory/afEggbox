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
	}

	@Contribute { serviceType=ScriptModules# }
	static Void contributeScriptModules(Configuration config) {
		config.add(ScriptModule("jquery"		).atUrl(`//code.jquery.com/jquery-1.11.2.min.js`).fallbackToUrl(`/js/jquery-1.11.2.min.js`))
		config.add(ScriptModule("bootstrap"		).atUrl(`/js/bootstrap.min.js`).requires("jquery"))
//		config.add(ScriptModule("fantomModules"	).atUrl(`/scripts/fantomModules.js`))
	}

	
	@Contribute { serviceType=InputSkins# }
	static Void contributeInputSkins(Configuration config) {
		config.overrideValue("email",		BootstrapInputSkin())
		config.overrideValue("text",		BootstrapInputSkin())
		config.overrideValue("password",	BootstrapInputSkin())
	}
	
//	@Contribute { serviceType=RequireJsConfigTweaks# }
//	static Void contributeRequireJsConfigTweaks(Configuration conf) {
//		conf["app.bundles"] = |Str:Obj? config| {
//			bundles := (Str:Str[]) config.getOrAdd("bundles") { [Str:Str[]][:] }
//			bundles["fantomModules"] = "pulse unscramble gridtilt onRevealLoadScript onReveal loadScript jsCookie".split
//		}
//	}
	
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
