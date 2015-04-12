using fanr
using afButter

** Not Registered
** ##############
** Only registered can publish to the repository. 
** Users authenticate themselves by suppling a username and password to the 'fanr' application.
**
** If no credentials are supplied when publishing a pod, the repo should respond with a
** HTTP status code of '401 - Unauthorised'.
** 
** Example
** -------
** Given my username is [steve.eynon]`set:username` and my password is [password]`set:password`
**  
** When I try to [publish a pod]`exe:publish` with no credentials
**  
** Then I should receive a HTTP status err of [401 - Unauthorized]`eq:httpStatus`. 
**
class TestFanrPublishNotRegistered : FanrFixture {
	Str?		username
	Str?		password
	Str?		httpStatus
	
	Void publish() {
		userDao.create(newUser(username, password))

		podFile := File.createTemp("afPodRepo_", ".pod").deleteOnExit
		try {
			fanrClient.publish(podFile)
		} catch (BadStatusErr err) {
			httpStatus = "${err.statusCode} - ${err.statusMsg}"
		}
	}
}
