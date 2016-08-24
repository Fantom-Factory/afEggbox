using afIoc
using afBedSheet
using fanr

const class FanrModule {

	static Void defineServices(ServiceDefinitions defs) {
		defs.add(FanrRepo#)
	}

	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(Configuration config) {
		
		//    from fanr::WebRepoMod
		//    Method   Uri                       Operation
		//    ------   --------------------      ---------
		//    GET      {base}/ping               ping meta-data
		//    GET      {base}/find/{name}        pod find current
		//    GET      {base}/find/{name}/{ver}  pod find
		//    GET      {base}/query?{query}      pod query
		//    POST     {base}/query              pod query
		//    GET      {base}/pod/{name}/{ver}   pod download
		//    POST     {base}/publish            publish pod
		//    GET      {base}/auth?{username}    authentication info
		
		base := "/fanr"
		config.add(Route(`${base}/ping`,	FanrHandler#onPing))
		config.add(Route(`${base}/find/**`,	FanrHandler#onFind))
		config.add(Route(`${base}/query`,	FanrHandler#onQuery, "GET POST"))
		config.add(Route(`${base}/pod/*/*`,	FanrHandler#onPod))
		config.add(Route(`${base}/publish`,	FanrHandler#onPublish, "POST"))
		config.add(Route(`${base}/auth`,	FanrHandler#onAuth))
	}
	
}
