using afIoc
using afButter
using util

** Latest Pod
** ##########
** The *find* URL is used to perform a an exact find.
** 
** If it does not contain a version part then the latest pod is returned.
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
**   afIoc  2.00
**   afIoc  1.69
** 
** When I query the repository with the URL [/find/afIoc]`exe:queryRepo(#TEXT)` it should return:
** 
**   exe:verifyJson(#TEXT)
**   {
**       "pod.name"    : "afIoc",
**       "pod.version" : "2.06",
**       "pod.depends" : "sys 1.0",
**       "pod.summary" : "A powerful Dependency Injection / Inversion Of Control framework",
**       "build.ts"    : "2006-06-06T06:06:00Z UTC"
**   }
** 
class TestFanrFindLatest : FanrFixture {

	Void createIocPod(Str name, Str version) {
		meta["pod.name"]	= name
		meta["pod.version"]	= version
		meta["pod.depends"]	= "sys 1.0"
		meta["pod.summary"]	= "A powerful Dependency Injection / Inversion Of Control framework"
		super.createPod
	}
}
