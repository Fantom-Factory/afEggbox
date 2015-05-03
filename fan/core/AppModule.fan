using afIoc
using afIocEnv
using afIocConfig
using afMorphia

@SubModule { modules=[FanrModule#, WebModule#] }
class AppModule {
	
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(RepoPodDao#)
		defs.add(RepoPodFileDao#)
		defs.add(RepoUserDao#)
	}

	@Contribute { serviceType=Converters# }
	static Void contributeConverters(Configuration config) {		
		config[RepoPodMeta#] = 	config.createProxy(Converter#, RepoPodMetaConverter#)
	}

	@Contribute { serviceType=ApplicationDefaults# }
	static Void contributeApplicationDefaults(Configuration config, IocEnv env) {
		
		if (env.isDev) {
			config[MorphiaConfigIds.mongoUrl]	= `mongodb://localhost:27017/podrepo-dev`
		}

		if (env.isTest) {
			config[MorphiaConfigIds.mongoUrl]	= `mongodb://localhost:27017/podrepo-test`
		}
		
		if (env.isProd) {
//			config[MorphiaConfigIds.mongoUrl]	= `mongodb://heroku:password@ds063630.mongolab.com:63630/bushmasters`
		}
	}

}
