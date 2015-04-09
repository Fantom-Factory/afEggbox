using fanr
using afButter

** Not Authenticated
** #################
**
** Only registered and authenticated users should be able to publish to the repository. 
** Users authenticate themselves by suppling a username and password to the 'fanr' application.
**  
** wrong password
** 
** Example
** -------
** Given I'm an [unauthorised user]`exe:unauthUser`, 
** when I publish [afTest01.pod]`exe:publish(#TEXT)`
** then I should receive a http status err of [401]`eq:statusCode`. 
** 
class TestFanrPublishNotAuthenticated : RepoFixture {
	FanrClient? fanrClient
	Int?		statusCode
	
	override Void setupFixture() {
		super.setupFixture
		fanrClient = FanrClient() { it.client = this.client }
	}
	
	Void unauthUser() {
		userDao.create(newUser("user.unauth", "password"))
		fanrClient.username = "user.unauth"
		fanrClient.password = "whoops"
	}
	
	Void publish(Str fileName) {
		try {
			fanrClient.publish(`test-spec/res/${fileName}`.toFile)
		} catch (BadStatusErr err) {
			statusCode = err.statusCode
		}
	}
}
