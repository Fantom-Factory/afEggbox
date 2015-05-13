using afIoc

class FandocModule {
	
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(HtmlWriter#)
	}
}
