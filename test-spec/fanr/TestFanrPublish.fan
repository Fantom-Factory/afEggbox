using fanr
using util

** Publish
** #######
** The "publish" URI is used to upload a new pod to the repository.
** 
** Publication is performed by POSTing a pod file to the '/publish' URI. 
** If the publication is successful, then a JSON data structure representing the pod is returned.
** 
** Pods may only be published by authenticated registered users. 
** 
**  
** Example
** -------
** Given I'm a [registered user]`exe:createUser` and have a pod with the following attributes:
** 
**   table:
**   row+exe:meta[#COL[0]] = #COL[1]
** 
**   name         value
**   -----        ----
**   pod.name     acmeWidgets
**   pod.version  1.3.68
**   pod.summary  Widgets for everyone!
**   pod.depends  sys 1.0; gfx 1.0; fwt 1.0
** 
** When I [publish]`exe:publish` it
** then I should receive the following JSON:
** 
**   exe:verifyJson(#TEXT, ["published":#FIXTURE.podSpec.meta])
**   {
**       "published" : {
**           "pod.name"    : "acmeWidgets",
**           "pod.version" : "1.3.68",
**           "pod.summary" : "Widgets for everyone!",
**           "pod.depends" : "sys 1.0; gfx 1.0; fwt 1.0"
**       }
**   }
** 
** The database should then hold an entry for an [acmeWidgets 1.3.68]`exe:findPod(#TEXT)` pod.
** 
** 
** Further Details
** ===============
** - [What if I supply the wrong authentication details?]`run:TestFanrPublishNotAuthenticated#`
** - [What if I'm not a registered user?]`run:TestFanrPublishNotRegistered#`
** 
class TestFanrPublish : FanrFixture {
	Str:Str		meta := Str:Str[:] { ordered = true }
	PodSpec?	podSpec
	
	Void createUser() {
		userDao.create(newUser("steve.eynon", "password"))
		fanrClient.username = "steve.eynon"
		fanrClient.password = "password"
	}

	Void publish() {
		podFile := File.createTemp("afPodRepo_", ".pod").deleteOnExit
		
		zip := Zip.write(podFile.out)
		zip.writeNext(`meta.props`).writeProps(meta)
		zip.close
		
		podSpec = fanrClient.publish(podFile)
	}
	
	Obj findPod(Str podName) {
		podDao[podName]
	}
}
