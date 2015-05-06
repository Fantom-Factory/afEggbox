using afBounce

** Basic Auth
** ##########
** 
** Example
** -------
** Given I am not logged in, when I try to visit the [My Pods Page]`exe:gotoPage(#TEXT)`
** then I get redirected to the [Login Page]`eq:renderedPageName`.
** 
class TestBasicAuth : WebFixture {

}
