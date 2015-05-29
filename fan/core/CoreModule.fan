using afIoc
using afIocEnv
using afIocConfig
using afMorphia

@SubModule { modules=[FanrModule#, WebModule#] }
class CoreModule {
	
	static Void defineServices(ServiceDefinitions defs) {
		
		defs.add(UserSession#)
		
		defs.add(RepoUserDao#)
		defs.add(RepoPodDao#)
		defs.add(RepoPodFileDao#)
		defs.add(RepoPodDocsDao#)
		defs.add(RepoPodSrcDao#)
		defs.add(RepoPodApiDao#)
		
		defs.add(DirtyCash#)
		defs.add(CorePods#)
	}

	@Build
	static PodRepoConfig buildPodRepoConfig(IocEnv iocEnv) {
		PodRepoConfig(iocEnv)
	}

	@Contribute { serviceType=Converters# }
	static Void contributeConverters(Configuration config) {		
		config[FandocUri#] 		= config.autobuild(FandocUriConverter#)
	}

	@Contribute { serviceType=RegistryStartup# }
	internal static Void contributeRegistryStartup(Configuration config) {
		config.set("afPodRepo.ensureIndexes", |->| {
			indexes := (Indexes) config.autobuild(Indexes#)
			indexes.ensureIndexes
		}).after("afMorphia.testConnection")
	}
	
	@Contribute { serviceType=ApplicationDefaults# }
	static Void contributeApplicationDefaults(Configuration config, PodRepoConfig repoConfig) {
		config[MorphiaConfigIds.mongoUrl]	= repoConfig.mongoDbUrl
	}
}
