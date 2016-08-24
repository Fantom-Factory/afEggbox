using afIoc
using afIocEnv
using afIocConfig
using afMorphia

@SubModule { modules=[FanrModule#, WebModule#] }
const class CoreModule {
	
	static Void defineServices(ServiceDefinitions defs) {
		
		defs.add(UserSession#)
		
		defs.add(RepoUserDao#)
		defs.add(RepoPodDao#)
		defs.add(RepoPodFileDao#)
		defs.add(RepoPodDocsDao#)
		defs.add(RepoPodSrcDao#)
		defs.add(RepoPodApiDao#)
		defs.add(RepoPodDownloadDao#)
		defs.add(RepoActivityDao#)
		
		defs.add(DirtyCash#)
		defs.add(CorePods#)
	}

	@Build
	static EggboxConfig buildEggboxConfig(IocEnv iocEnv) {
		EggboxConfig(iocEnv)
	}

	@Contribute { serviceType=Converters# }
	static Void contributeConverters(Configuration config) {		
		config[RepoPodMeta#] 	= config.build(RepoPodMetaConverter#)
		config[FandocUri#] 		= config.build(FandocUriConverter#)
	}

	internal static Void onRegistryStartup(Configuration config) {
		config.set("afEggbox.ensureIndexes", |->| {
			indexes := (Indexes) config.autobuild(Indexes#)
			indexes.ensureIndexes
		}).after("afMorphia.testConnection")
	}
	
	@Contribute { serviceType=ApplicationDefaults# }
	static Void contributeApplicationDefaults(Configuration config, EggboxConfig eggboxConfig) {
		config[MorphiaConfigIds.mongoUrl]	= eggboxConfig.mongoDbUrl
	}
}
