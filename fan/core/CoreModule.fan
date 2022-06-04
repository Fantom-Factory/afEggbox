using afIoc
using afIocEnv::IocEnv
using afIocConfig
using afMorphia::BsonConvs

@SubModule { modules=[FanrModule#, WebModule#] }
const class CoreModule {
	
	Void defineServices(RegistryBuilder defs) {
		defs.addService(UserSession#)
		
		defs.addService(RepoUserDao#)
		defs.addService(RepoPodDao#)
		defs.addService(RepoPodFileDao#)
		defs.addService(RepoPodDocsDao#)
		defs.addService(RepoPodSrcDao#)
		defs.addService(RepoPodApiDao#)
		defs.addService(RepoPodDownloadDao#)
		defs.addService(RepoActivityDao#)
		
		defs.addService(DirtyCash#)
		defs.addService(CorePods#)
	}

	@Build
	EggboxConfig buildEggboxConfig(IocEnv iocEnv) {
		EggboxConfig(iocEnv)
	}

	@Contribute { serviceType=BsonConvs# }
	Void contributeConverters(Configuration config) {		
		config[RepoPodMeta#] 	= RepoPodMetaConverter()
		config[FandocUri#] 		= config.build(FandocUriConverter#)
	}

	internal Void onRegistryStartup(Configuration config) {
		config.set("afEggbox.ensureIndexes", |->| {
			indexes := (Indexes) config.build(Indexes#)
			indexes.ensureIndexes
		})
	}
	
	// TODO use config.props
	@Contribute { serviceType=ApplicationDefaults# }
	Void contributeApplicationDefaults(Configuration config, EggboxConfig eggboxConfig) {
		config["afMorphia.mongoUrl"]		= eggboxConfig.mongoDbUrl
		config["afMorphia.seqsCollName"]	= "IntSequences" }
}
