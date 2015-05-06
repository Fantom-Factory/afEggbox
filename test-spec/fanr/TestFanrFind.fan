using afIoc
using afButter
using util

** Find
** ####
** The *find* URL is used to perform a an exact find.
** 
** It responds with a JSON map containing the the pod metadata as string name/value pairs. 
** 
** Example
** -------
** Given the repository has a pod with the following meta:
** 
**   table:
**   row+exe:meta[#COL[0]] = #COL[1]
** 
**   Name         Value
**   -----------  -----------
**   pod.name     xml
**   pod.version  1.0.67
**   pod.depends  sys 1.0
**   pod.summary  XML Parser and Document Modelling
** 
** [(*)]`exe:createPod`
** when I query the repository with the URL [/find/xml/1.0.67]`exe:queryRepo(#TEXT)` 
** then it should return the following JSON:
** 
**   exe:verifyJson(#TEXT)
**   {
**       "pod.name"    : "xml",
**       "pod.version" : "1.0.67",
**       "pod.depends" : "sys 1.0",
**       "pod.summary" : "XML Parser and Document Modelling",
**       "build.ts"    : "2006-06-06T06:06:00Z UTC"
**   }
**
** 
** Further Details
** ===============
**  - [What if the pod doesn't exist?]`run:TestFanrFindNotFound#`
**  - [How do I find the latest pod?]`run:TestFanrFindLatest#`
class TestFanrFind : FanrFixture {
}
