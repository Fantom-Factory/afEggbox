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
** When I try to [publish a pod]`exe:publish` with no credentials
**  
** Then I should receive a HTTP status err of [401 - Unauthorized]`eq:httpStatus`. 
**
class TestFanrPublishNotRegistered : FanrFixture {
	
	Void publish() {
		fanrClient.username = null
		fanrClient.password = null
		super.publishToRepo
	}
}
