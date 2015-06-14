using util

** Read
** ####
** The *read* URL is used to download a specific version of a pod.
** 
** But if the pod queried for does not exist in the repository, then a 404 should be returned.
** 
** Example
** -------
** When I query the repository for a non-existent pod with the URL [/pod/missing/1.0.67]`exe:readFromRepo(#TEXT)`
** then it should return a status code of [404 - Not Found]`eq:httpStatus`.
** 
class TestFanrReadNotFound : FanrFixture {
}
