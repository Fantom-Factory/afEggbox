using fanr
using afButter

** Not Authenticated
** #################
** Only registered can publish to the repository. 
** Users authenticate themselves by suppling a username and password to the 'fanr' application.
**
** If the wrong password is supplied then, when publishing a pod, the repo should respond with a
** HTTP status code of '401 - Unauthorised'.
** 
** Example
** -------
** Given my username is [steve.eynon]`set:username` and my password is [password]`set:password`
**  
** When I try to publish a pod with the password [whoops]`exe:publish(#TEXT)`
**  
** Then I should receive a HTTP status err of [401 - Unauthorized]`eq:httpStatus`. 
** 
class TestFanrPublishNotAuthenticated : RepoFixture {
	FanrClient? fanrClient
	Str?		username
	Str?		password
	Str?		httpStatus
	
	override Void setupFixture() {
		super.setupFixture
		fanrClient = FanrClient() { it.client = this.client }
	}
	
	Void publish(Str wrongPassword) {
		userDao.create(newUser(username, password))
		fanrClient.username = username
		fanrClient.password = wrongPassword

		podFile := File.createTemp("afPodRepo_", ".pod").deleteOnExit
		try {
			fanrClient.publish(podFile)
		} catch (BadStatusErr err) {
			httpStatus = "${err.statusCode} - ${err.statusMsg}"
		}
	}
}
