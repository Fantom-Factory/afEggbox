using util

** Auth
** ####
** The "auth" URI is used to discover which algorithms are supported by the server and to acquire the public salt for the user.
** 
** The "auth" URI takes a username as a query string. The response will be a JSON data structure with a map of name/value pairs.
** 
** 
** Example
** -------
** When I query the auth URI with the username [someone]`exe:auth(#TEXT)`
** it should return the following JSON:
** 
**   exe:verifyJson(#TEXT, #FIXTURE.jsonObj)
**   {
**       "username"            : "someone",
**       "ts"                  : "2011-07-13T14:50:01.865Z UTC",
**       "secretAlgorithms"    : "SALTED-HMAC-SHA1",
**       "signatureAlgorithms" : "HMAC-SHA1",
**       "salt"                : "3d98fe2bc7cd13e02344a76400e1c212"
**   }
** 
class TestFanrAuth : FanrFixture {
	[Str:Obj?]?	jsonObj
	
	Void auth(Str username) {
		userDao.create(newUser(username, "password"))
		fanrClient.username = username
		fanrClient.password = "password"
		jsonObj = fanrClient.auth()
	}
	
	override Void verifyJson(Str json, Str:Obj? actualJsonObj) {
		expectedJsonObj := (Str:Obj?) JsonInStream(json.in).readJson
		expectedJsonObj["salt"] = "salt"
		actualJsonObj  ["salt"] = "salt"
		expectedJsonObj["ts"]   = "timestamp"
		actualJsonObj  ["ts"]   = "timestamp"
		verifyEq(expectedJsonObj.toStr, actualJsonObj.toStr)	// don't compare Map types

	}
}
