using util

** Ping
** ####
** The *ping* URL is used to query the server to check that is alive, test credentials, and query server metadata.
** It is always publicly accessible and responds with a JSON map of string name/value pairs.
** 
** 
** Example
** -------
** When I query the repository with the URL [/ping]`exe:queryRepo(#TEXT)` 
** then it should return the following JSON:
** 
**   exe:verifyJson(#TEXT)
**   {
**       "fanr.type"    : "afEggbox::FanrRepo",
**       "fanr.version" : "1.0.77",
**   }
** 
** 
** Further Details
** ===============
** - [What if I supply the wrong authentication details?]`run:TestFanrPingNotAuthenticated#`
** 
class TestFanrPing : FanrFixture {
}
