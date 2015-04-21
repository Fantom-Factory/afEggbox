using util

** Limit Results
** #############
** The *query* URL is used to perform a repo query.
**  
** You can specify the 'Fanr-NumVersions' header to limit the number of versions returned for each pod. The default version limit is three.
** 
** 
** Example
** -------
** Given the repository has the following pods:
** 
**   table:
**   row+exe:createIocPod(#COL[0], #COL[1], #COL[2])
**   Name    Version  Summary
**   -----   -------  -------
**   afPod1  1.01     pod-1
**   afPod2  1.02     pod-2
**   afPod3  1.03     pod-3
**   afPod4  1.04     pod-4
** 
** When I query the repository with the URL [/query?*]`exe:queryRepo(#TEXT)` *without* a 'Fanr-NumVersions' header
** then it should return the following JSON:
** 
** pre>
** exe:verifyJson(#TEXT)
** {
**   "pods": [
**     {
**       "pod.name"    : "afPod1",
**       "pod.version" : "1.01",
**       "pod.depends" : "sys 1.0",
**       "pod.summary" : "pod-1"
**     },
**     {
**       "pod.name"    : "afPod2",
**       "pod.version" : "1.02",
**       "pod.depends" : "sys 1.0",
**       "pod.summary" : "pod-2"
**     },
**     {
**       "pod.name"    : "afPod3",
**       "pod.version" : "1.03",
**       "pod.depends" : "sys 1.0",
**       "pod.summary" : "pod-3"
**     }
**   ]
** }
** <pre
** 
** If I set the 'Fanr-NumVersions' header set to [1]`set:numVersions` then 
** when I query the repository with the URL [/query?*]`exe:queryRepo(#TEXT)`  
** it should return the following limited JSON:
** 
** pre>
** exe:verifyJson(#TEXT)
** {
**   "pods": [
**     {
**       "pod.name"    : "afPod1",
**       "pod.version" : "1.01",
**       "pod.depends" : "sys 1.0",
**       "pod.summary" : "pod-1"
**     }
**   ]
** }
** <pre
**
class TestFanrQueryLimit : FanrFixture {
	Str? numVersions

	Void createIocPod(Str name, Str version, Str summary) {
		meta["pod.name"]	= name
		meta["pod.version"]	= version
		meta["pod.depends"]	= "sys 1.0"
		meta["pod.summary"]	= summary
		super.createPod
	}
	
	override Void queryRepo(Str url) {
		jsonObj = null
		httpStatus = null
		if (numVersions != null)
			client.stickyHeaders.stickyHeaders["Fan-NumVersions"] = numVersions
		super.queryRepo(url)
	}
}
