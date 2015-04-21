using util
using fanr
using afButter

abstract class FanrFixture : RepoFixture {
	FanrClient? fanrClient
	Str:Str		meta	:= [:] { ordered = true }
	[Str:Obj?]?	jsonObj
	Buf?		resBody
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

	File podFile() {
		podFile := File.createTemp("afPodRepo_", ".pod").deleteOnExit
		zip := Zip.write(podFile.out)
		zip.writeNext(`meta.props`).writeProps(meta)
		zip.close
		return podFile
	}
	
	Void createPod() {
		podFile := podFile
		pod := podDao.create(RepoPod(podFile, newUser))
		podFileDao.create(RepoPodFile(pod, podFile))
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

	Void publishToRepo() {
		podFile	:= podFile
		try {
			response	:= fanrClient.publish(podFile)
			httpStatus	= "${response.statusCode} - ${response.statusMsg}"
			jsonObj		= response.body.jsonMap
			
		} catch (BadStatusErr err) {
			httpStatus = "${err.statusCode} - ${err.statusMsg}"
		} finally {
			podFile.delete
		}
	}

	Void readFromRepo(Str url) {
		try {
			response	:= fanrClient.query(url.toUri)
			httpStatus	= "${response.statusCode} - ${response.statusMsg}"
			resBody		= response.body.buf
			
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
