using util

** Query
** #####
** The *query* URL is used to perform a repo query. 
** The query string may be passed in the URI query parameter using a GET request or may be passed as the request body of a POST request.
** 
** The query response is a JSON map containing the "pods" key which is a list of pod metadata as string name/value pairs. 
** 
** 
** Example
** -------
** Given the repository has the following pods:
** 
**   table:
**   row+exe:createIocPod(#COL[0], #COL[1])
**   Name   Version
**   -----  -------
**   afIoc  2.06
**   afIoc  1.69
** 
** When I query the repository with the URL [/query?afIoc]`exe:queryRepo(#TEXT)` 
** then it should return the following JSON:
** 
** pre>
** exe:verifyJson(#TEXT)
** {
**   "pods": [
**     {
**       "pod.name"    : "afIoc",
**       "pod.version" : "2.06",
**       "pod.depends" : "sys 1.0",
**       "pod.summary" : "A powerful Dependency Injection / Inversion Of Control framework",
**     },
**     {
**       "pod.name"    : "afIoc",
**       "pod.version" : "1.69",
**       "pod.depends" : "sys 1.0",
**       "pod.summary" : "A powerful Dependency Injection / Inversion Of Control framework",
**     }
**   ]
** }
** <pre
**
** 
** Further Details
** ===============
**  - [How do I limit the number of results?]`run:TestFanrQueryLimit#`
** 
class TestFanrQuery : FanrFixture {

	Void createIocPod(Str name, Str version) {
		meta["pod.name"]	= name
		meta["pod.version"]	= version
		meta["pod.depends"]	= "sys 1.0"
		meta["pod.summary"]	= "A powerful Dependency Injection / Inversion Of Control framework"
		super.createPod
	}
}
