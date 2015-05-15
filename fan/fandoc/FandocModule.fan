using afIoc

class FandocModule {
	
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(HtmlWriter#)
		defs.add(PreTextProcessors#)
	}
	
	@Contribute { serviceType=PreTextProcessors# }
	static Void contributePreTextProcessors(Configuration config) {
		config["syntax"]	= config.autobuild(SyntaxPreProcessor#)
		config["table"]		= config.autobuild(TablePreProcessor#)
	}
}
