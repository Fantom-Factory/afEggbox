using afIoc

class FandocModule {
	
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(Fandoc#)
		defs.add(PreTextProcessors#)
		defs.add(LinkResolvers#)
		defs.add(SyntaxWriter#)
	}
	
	@Contribute { serviceType=PreTextProcessors# }
	static Void contributePreTextProcessors(Configuration config) {
		config["syntax"]	= config.autobuild(SyntaxPreProcessor#)
		config["table"]		= config.autobuild(TablePreProcessor#)
	}
}
