using util

** Auth
** ####
** The *auth* URL is used to discover which algorithms are supported by the server and to acquire the public salt for the user.
** 
** It takes a username as a query string and responds with a JSON data structure of authentication information.
** 
** 
** Example
** -------
** Given the repository has a user named [someone]`set:username`, 
** when I query the repository with the URL [/auth?someone]`exe:queryRepo(#TEXT)` 
** then it should return the following JSON:
** 
**   exe:verifyJson(#TEXT)
**   {
**       "username"            : "someone",
**       "ts"                  : "2011-07-13T14:50:01.865Z UTC",
**       "secretAlgorithms"    : "SALTED-HMAC-SHA1",
**       "signatureAlgorithms" : "HMAC-SHA1",
**       "salt"                : "3d98fe2bc7cd13e02344a76400e1c212"
**   }
** 
class TestFanrAuth : FanrFixture {

	override Void verifyJson(Str json) {
		expectedJsonObj := (Str:Obj?) JsonInStream(json.in).readJson
		expectedJsonObj	["salt"] = "salt"
		expectedJsonObj	["ts"]   = "timestamp"
		if (jsonObj != null) {
			if (jsonObj.containsKey("salt"))
				jsonObj  ["salt"] = "salt"
			if (jsonObj.containsKey("ts"))
				jsonObj  ["ts"]   = "timestamp"
		}
		verifyEq(expectedJsonObj.toStr, jsonObj?.toStr)	// don't compare Map types
	}
}
