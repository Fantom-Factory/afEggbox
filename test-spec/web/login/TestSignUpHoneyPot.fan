using afBounce

** Sign Up Honey Pot
** #################
** 
** Example
** -------
** Given I'm on the [Signup Page]`exe:showPage(#TEXT)`, when I enter the following data:
** 
**   table:
**   row+exe:input(#COL[0]).value = #COL[1]
** 
**   --------------  ----------------------
**   #email          micky.mouse@disney.com
**   #password       password
**   #passwordAgain  password
** 
** and click [Sign Up]`exe:click(#TEXT)`
** then the response should be [403 - Forbidden]`eq:httpStatus`.
** 
class TestSignUpHoneyPot : WebFixture {

	override Void setupFixture() {
		client.errOn4xx.enabled = false
	}
}
