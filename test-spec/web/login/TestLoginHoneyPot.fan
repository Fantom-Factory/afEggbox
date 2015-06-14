using afBounce

** Login Honey Pot
** ###############
** 
** Example
** -------
** Given I'm on the [Login Page]`exe:showPage(#TEXT)`, when I enter the following data:
** 
**   table:
**   row+exe:input(#COL[0]).value = #COL[1]
** 
**   --------------  ----------------------
**   #email          micky.mouse@disney.com
**   #password       password
**   #passwordAgain  password
** 
** and click [Login]`exe:click(#TEXT)`
** then the response should be [403 - Forbidden]`eq:httpStatus`.
** 
class TestLoginHoneyPot : WebFixture {

	override Void setupFixture() {
		client.errOn4xx.enabled = false
	}
}
