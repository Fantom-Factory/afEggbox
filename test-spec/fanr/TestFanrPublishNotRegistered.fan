using fanr
using afButter

** Not Registered
** ##############
**
** Only registered and authenticated users should be able to publish to the repository. 
** They authenticate themselves by suppling a username and password to the 'fanr' application.
**  
** Example
** -------
** Given I'm not registered on the system 
** when I publish [afTest01.pod]`exe:publish(#TEXT)`
** then I should receive a http status err of [401]`eq:statusCode`. 
** 
class TestFanrPublishNotRegistered : RepoFixture {
	FanrClient? fanrClient
	Int?		statusCode
	
	override Void setupFixture() {
		super.setupFixture
		fanrClient = FanrClient() { it.client = this.client }
	}
	
	Void publish(Str fileName) {
		try {
			fanrClient.publish(`test-spec/res/${fileName}`.toFile)
		} catch (BadStatusErr err) {
			statusCode = err.statusCode
		}
	}
}
