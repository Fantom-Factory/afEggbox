using afButter

** Ping
** ####
** The "ping" URI is used to query the server to check that is alive, test credentials, and query server metadata.
** 
** If the 'Fanr-Username' HTTP header is specified then authentication will be checked and an error returned if the credentials are invalid.
** 
** 
** Example
** -------
** Given my username is [steve.eynon]`set:username` and my password is [password]`set:password`
**  
** When I ping the repository with the password [whoops]`exe:ping(#TEXT)`
**  
** Then I should receive a HTTP status err of [401 - Unauthorized]`eq:httpStatus`. 
** 
class TestFanrPingNotAuthenticated : FanrFixture {
	Str?		username
	Str?		password
	Str?		httpStatus
	
	Void ping(Str wrongPassword) {
		userDao.create(newUser(username, password))
		fanrClient.username = username
		fanrClient.password = wrongPassword

		try {
			fanrClient.ping()
		} catch (BadStatusErr err) {
			httpStatus = "${err.statusCode} - ${err.statusMsg}"
		}
	}
}
