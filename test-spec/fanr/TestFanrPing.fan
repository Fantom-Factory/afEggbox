using util

** Ping
** ####
** The "ping" URI is used to query the server to check that is alive, test credentials, and query server metadata.
** 
** The "ping" URI is always publicly accessible and responds with a JSON map of string name/value pairs.
** 
** 
** Example
** -------
** When I [ping]`exe:ping` the repository it
** should return the following JSON:
** 
**   exe:verifyJson(#TEXT, #FIXTURE.pingRes)
**   {
**       "fanr.version" : "1.0.67",
**       "fanr.type"    : "afPodRepo::MongoRepo"
**   }
** 
** 
** Further Details
** ===============
** - [What if I supply the wrong authentication details?]`run:TestFanrPingNotAuthenticated#`
** 
class TestFanrPing : FanrFixture {
	[Str:Obj?]?	pingRes
	
	Void ping() {
		pingRes = fanrClient.ping()
	}
}
