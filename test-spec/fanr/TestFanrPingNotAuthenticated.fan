using afButter

** Not Authenticated
** #################
** The *ping* URL is used to query the server to check that is alive, test credentials, and query server metadata.
** 
** If the 'Fanr-Username' HTTP header is specified then authentication will be checked and an error returned if the credentials are invalid.
** 
** 
** Example
** -------
** Given my username is [steve.eynon]`set:username` and my password is [password]`set:password`
** then should I mistakenly enter my password as [whoops]`set:fanrClient.password` 
** and query the repository at the URL [/ping]`exe:queryRepo(#TEXT)`
** then I should receive a HTTP status err of [401 - Unauthorized]`eq:httpStatus`. 
** 
class TestFanrPingNotAuthenticated : FanrFixture {	
}
