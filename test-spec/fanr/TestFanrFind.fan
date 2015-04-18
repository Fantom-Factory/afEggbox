using afIoc
using util

** Find
** ####
** The "find" URI is used to perform a an exact find.
** 
** The find response is a JSON map containing the the pod metadata as string name/value pairs. 
** 
** Example
** -------
** When I query the find URI for the pod [xml]`set:podName` and version [1.0.67]`set:podVersion`
** it should [return]`exe:find` the following JSON:
** 
**   exe:verifyJson(#TEXT, #FIXTURE.jsonObj)
**   {
**       "pod.name":"xml",
**       "pod.version":"1.0.67",
**       "pod.depends":"sys 1.0",
**       "pod.summary":"XML Parser and Document Modelling"
**   }
**
** Not Found
** ========= 
** If the pod is not found, then 404 is returned.
** 
** Example
** -------
** When I query the find URI for a non-existent pod named [missing]`set:podName` it should return a [404]`eq:findPod` status code.
** 
class TestFanrFind : FanrFixture {
	Str?		podName
	Str? 		podVersion
	[Str:Obj?]?	jsonObj
	
	Void find() {
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

		jsonObj = fanrClient.find(podName, podVersion)
	}
}
