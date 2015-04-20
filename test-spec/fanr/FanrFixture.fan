using util
using fanr
using afButter

abstract class FanrFixture : RepoFixture {
	FanrClient? fanrClient
	Str:Str		meta	:= [:] { ordered = true }
	[Str:Obj?]?	jsonObj
	Str?		httpStatus
	
	Str username {
		get { fanrClient.username }
		set { fanrClient.username = it
			createOrUpdateUser(newUser(it, fanrClient.password))
		} 
	}

	Str password {
		get { fanrClient.password }
		set { fanrClient.password = it
			createOrUpdateUser(newUser(fanrClient.username, it))
		} 
	}

	override Void setupFixture() {
		super.setupFixture
		fanrClient = FanrClient() { it.client = this.client }
	}

	Void createPod() {
		podFile := File.createTemp("afPodRepo_", ".pod").deleteOnExit
		
		zip := Zip.write(podFile.out)
		zip.writeNext(`meta.props`).writeProps(meta)
		zip.close

		podDao.create(RepoPod(podFile, newUser))
		podFile.delete
	}

	Void queryRepo(Str url) {
		try {
			response	:= fanrClient.query(url.toUri)
			httpStatus	= "${response.statusCode} - ${response.statusMsg}"
			jsonObj		= response.body.jsonMap
			
		} catch (BadStatusErr err) {
			httpStatus = "${err.statusCode} - ${err.statusMsg}"
		}
	}

	virtual Void verifyJson(Str json) {
		expectedJsonObj := JsonInStream(json.in).readJson
		verifyEq(expectedJsonObj.toStr, jsonObj.toStr)	// don't compare Map types
	}
	
	private Void createOrUpdateUser(RepoUser user) {
		existing := userDao.findByUsername(user.userName)
		if (existing != null) 
			userDao.delete(existing)
		userDao.create(user)
	}
}
