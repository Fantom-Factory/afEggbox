using afIoc
using afButter
using util


** Find
** ####
** The "find" URI is used to perform a an exact find.
** 
** The find response is a JSON map containing the the pod metadata as string name/value pairs. 
** 
** Example
** -------
** Given the repository has a pod called [xml]`set:podName` with a version of [1.0.67]`set:podVersion`, 
** when I query the [find URI]`exe:makePod; #FIXTURE.findPod` for the pod it should return the following JSON:
** 
**   exe:verifyJson(#TEXT, #FIXTURE.jsonObj)
**   {
**       "pod.name"    : "xml",
**       "pod.version" : "1.0.67",
**       "pod.depends" : "sys 1.0",
**       "pod.summary" : "XML Parser and Document Modelling"
**   }
**
** 
** 
** Not Found
** ========= 
** If the pod is not found, then 404 is returned.
** 
** Example
** -------
** When I query the find URI for a non-existent pod named [missing]`set:podName` it should [return]`exe:findPod` a [404]`eq:httpStatus` status code.
** 
** 
** 
** Find Latest Pod
** ===============
** If the find URI does not contain a version part then the latest pod is returned.
** 
** Example
** -------
** Given the repository has the following pods:
** 
**   table:
**   row+exe:createPod(#COL[0], #COL[1])
**   Name   Version
**   -----  ------
**   afIoc  2.06
**   afIoc  2.00
**   afIoc  1.69
** 
** When I query the find URI for [afIoc]`exe:setIoc` it should return:
** 
**   exe:verifyJson(#TEXT, #FIXTURE.jsonObj)
**   {
**       "pod.name"    : "afIoc",
**       "pod.version" : "2.06",
**       "pod.depends" : "sys 1.0",
**       "pod.summary" : "A powerful Dependency Injection / Inversion Of Control framework"
**   }
** 
class TestFanrFind : FanrFixture {
	Str?			podName
	Str? 			podVersion
	[Str:Obj?]?		jsonObj
	Int?			httpStatus

	Void makePod() {
		podFile := File.createTemp("afPodRepo_", ".pod").deleteOnExit
		
		zip := Zip.write(podFile.out)
		zip.writeNext(`meta.props`).writeProps([
			"pod.name"		: podName,
			"pod.version"	: podVersion,
			"pod.depends"	: "sys 1.0",
			"pod.summary"	: "XML Parser and Document Modelling"
		])
		zip.close

		podDao.create(RepoPod(podFile, newUser))
	}

	Void createPod(Str name, Str version) {
		podFile := File.createTemp("afPodRepo_", ".pod").deleteOnExit
		
		zip := Zip.write(podFile.out)
		zip.writeNext(`meta.props`).writeProps([
			"pod.name"		: name,
			"pod.version"	: version,
			"pod.depends"	: "sys 1.0",
			"pod.summary"	: "A powerful Dependency Injection / Inversion Of Control framework"
		])
		zip.close

		podDao.create(RepoPod(podFile, newUser))		
	}

	
	Void findPod() {
		try {
			jsonObj = fanrClient.find(podName, podVersion).body.jsonMap
		} catch (BadStatusErr err) {
			httpStatus = err.statusCode
		}
	}
	
	Int findPodStatus() {
		fanrClient.find(podName, podVersion).statusCode		
	}
	
	Void setIoc() {
		podName = "afIoc"
		podVersion = null
		httpStatus = null
		jsonObj = fanrClient.find(podName, podVersion).body.jsonMap
	}
}
