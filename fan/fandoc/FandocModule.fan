using afIoc

const class FandocModule {
	
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(FandocWriter#)
		defs.addService(PreTextProcessors#)
		defs.addService(LinkResolvers#)
		defs.addService(SyntaxWriter#)

		defs.addService(InvalidLinks#)	// shouldn't be here
	}
	
	@Contribute { serviceType=PreTextProcessors# }
	static Void contributePreTextProcessors(Configuration config) {
		config["syntax"]	= config.build(SyntaxPreProcessor#)
		config["table"]		= config.build(TablePreProcessor#)
	}
	
	@Contribute { serviceType=LinkResolvers# }
	static Void contributeLinkResolvers(Configuration config) {
		config["literal"]	= LiteralLinkResolver()
		config["anchor"]	= AnchorLinkResolver()
		config["fantom"]	= config.build(FantomLinkResolver#)
		config["fandoc"]	= config.build(FandocLinkResolver#)
		config["pod"]		= config.build(PodLinkResolver#)
		config["fan"]		= config.build(FanLinkResolver#)
		config["article"]	= ArticleLinkResolver()
	}
}
