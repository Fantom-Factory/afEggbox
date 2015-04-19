using util

** fanr
** ####
** Fantom ships with the command line tool *fanr* which allows you to query and download pods from a remote repository.
** 
** Alien-Factory's Pod Repository aims to be compatible with *fanr* and so should support the HTTP REST protocol as outlined 
** in the fanr [Web Repository]`http:docFanr::WebRepos` documentation.
** 
** pre>
** Method   Uri                       Operation
** ------   --------------------      ---------
** GET      {base}/ping               ping meta-data
** GET      {base}/find/{name}/{ver}  find pod
** GET      {base}/query?{query}      pod query
** POST     {base}/query              pod query
** GET      {base}/pod/{name}/{ver}   pod download
** POST     {base}/publish            publish pod
** GET      {base}/auth?{username}    authentication info
** <pre
** 
** The following sections details the various features of the protocol:
** 
**  - [Authentication]`run:TestFanrAuth#`: authentication and digital signatures
**  - [Ping]`run:TestFanrPing#`: ping a server's meta-data
**  - [Find]`run:TestFanrFind#`: find exact match for pod name/version
**  - Query: query the repository for set of pods
**  - Read: download a pod for installation
**  - [Publish]`run:TestFanrPublish#`: upload a pod to add to the repository
** 
class TestFanr : RepoFixture { }

abstract class FanrFixture : RepoFixture {
	FanrClient? fanrClient
	
	override Void setupFixture() {
		super.setupFixture
		fanrClient = FanrClient() { it.client = this.client }
	}
	
	virtual Void verifyJson(Str json, Str:Obj? actualJsonObj) {
		expectedJsonObj := JsonInStream(json.in).readJson
		verifyEq(expectedJsonObj.toStr, actualJsonObj.toStr)	// don't compare Map types
	}
}
