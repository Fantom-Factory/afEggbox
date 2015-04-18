using afIoc
using afBedSheet
using fanr

class FanrModule {

	static Void defineServices(ServiceDefinitions defs) {
		defs.add(MongoRepo#)
		defs.add(MongoRepoAuth#)
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
		
		config.add(Route(`/ping`,		FanrHandler#onPing))
		config.add(Route(`/find/**`,	FanrHandler#onFind))
//		config.add(Route(`/query`,		FanrHandler#onQuery, "GET POST"))
//		config.add(Route(`/pod/*/*`,	FanrHandler#onPod))
		config.add(Route(`/publish`,	FanrHandler#onPublish, "POST"))
		config.add(Route(`/auth`,		FanrHandler#onAuth))
	}
	
}
