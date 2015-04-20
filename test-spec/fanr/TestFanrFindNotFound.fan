using afIoc
using afButter
using util

** Not Found
** #########
** The *find* URL is used to perform a an exact find.
** 
** But if the pod is not found, then a 404 should be returned.
** 
** Example
** -------
** When I query the repository for a non-existent pod with the URL [/find/missing/1.0.67]`exe:queryRepo(#TEXT)`
** then it should return a status code of [404 - Not Found]`eq:httpStatus`.
** 
class TestFanrFindNotFound : FanrFixture {
}
