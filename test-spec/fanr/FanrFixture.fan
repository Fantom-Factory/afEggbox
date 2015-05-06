using util
using fanr
using afButter

abstract class FanrFixture : RepoFixture {
	FanrClient? fanrClient
	Str:Str		meta	:= [:] { ordered = true }
	[Str:Obj?]?	jsonObj
	Buf?		resBody
	Str?		httpStatus
	
	Uri username {
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
		fanrClient = FanrClient() {
			it.client = this.client
		}
		meta["build.ts"] = "2006-06-06T06:06:00Z UTC"
	}

	Buf podBuf() {
		podBuf := Buf()
		zip := Zip.write(podBuf.out)
		zip.writeNext(`meta.props`).writeProps(meta)
		zip.close
		return podBuf.flip
	}
	
	Void createPod() {
		podBuf := podBuf
		pod := podDao.create(RepoPod(newUser, podBuf))
		podFileDao.create(RepoPodFile(pod, podBuf))
	}

	virtual Void queryRepo(Str url) {
		try {
			response	:= fanrClient.query(url.toUri)
			httpStatus	= "${response.statusCode} - ${response.statusMsg}"
			jsonObj		= response.body.jsonMap
			
		} catch (BadStatusErr err) {
			httpStatus = "${err.statusCode} - ${err.statusMsg}"
			jsonObj		= ["code":err.statusCode, "msg":err.statusMsg]
		}
	}

	Void publishToRepo() {
		podFile	:= podBuf
		try {
			response	:= fanrClient.publish(podFile)
			httpStatus	= "${response.statusCode} - ${response.statusMsg}"
			jsonObj		= response.body.jsonMap
			
		} catch (BadStatusErr err) {
			httpStatus = "${err.statusCode} - ${err.statusMsg}"
			jsonObj		= ["code":err.statusCode, "msg":err.statusMsg]
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

	virtual Void verifyJson(Str jsonStr) {
		expected := (Str:Obj?) JsonInStream(jsonStr.in).readJson
		verifyEq(expected.toStr, jsonObj.toStr)	// don't compare Map types
	}
}
