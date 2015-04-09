using fanr

** Publish
** #######
** The "publish" URI is used to upload a new pod to the repository.
** 
** Server side permission for the "publish" URI is controlled by the WebRepoAuth.allowPublish method.
** 
** Publication is performed by POSTing a pod file to the "publish" URI. 
** If the publication is successful, then a JSON data structure is returned.
** 
**  
** Example
** -------
** Given I'm a [registered user]`exe:createUser`, 
** when I publish [afTest01.pod]`exe:publish(#TEXT)`
** then I should receive a PodSpec with name [afTest01]`eq:podSpec.name` and version [1.6.9]`eq:podSpec.version`. 
** 
** {"published": {
**    "pod.name":"acmeWidgets",
**    "pod.version":"1.3.68",
**    "pod.depends":"sys 1.0, gfx 1.0, fwt 1.0",
**   }
** }
** 
** Further Details
** ===============
** - [What if I supply the wrong authentication details?]`run:TestFanrPublishNotAuthenticated#`
** - [What if I'm not a registered user?]`run:TestFanrPublishNotRegistered#`
class TestFanrPublish : RepoFixture {
	FanrClient? fanrClient
	PodSpec?	podSpec
	
	override Void setupFixture() {
		super.setupFixture
		fanrClient = FanrClient() { it.client = this.client }
	}
	
	Void createUser() {
		userDao.create(newUser("steve.eynon", "password"))
		fanrClient.username = "steve.eynon"
		fanrClient.password = "password"
	}

	
	Void publish(Str fileName) {
		podSpec = fanrClient.publish(`test-spec/res/${fileName}`.toFile)
	}
}
