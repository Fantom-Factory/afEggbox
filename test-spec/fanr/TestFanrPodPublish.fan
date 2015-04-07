using fanr

** Fanr :: Pod Publishing
** ######################
**
** 
**  
** Example
** -------
** Given I'm an [authorised user]`exe:authUser`, 
** when I publish [afTest01.pod]`exe:publish(#TEXT)`
** then I should receive a PodSpec with name [afTest01]`eq:podSpec.name` and version [1.6.9]`eq:podSpec.version`. 
** 
class TestFanrPodPublish : RepoFixture {
	FanrClient? fanrClient
	PodSpec?	podSpec
	
	override Void setupFixture() {
		super.setupFixture
		fanrClient = FanrClient() { it.client = this.client }
	}
	
	Void authUser() {
		userDao.create(newUser("user.auth"))
		fanrClient.username = "user.auth"
		fanrClient.password = "password"
	}
	
	Void publish(Str fileName) {
		podSpec = fanrClient.publish(`test-spec/res/${fileName}`.toFile)
	}
}
