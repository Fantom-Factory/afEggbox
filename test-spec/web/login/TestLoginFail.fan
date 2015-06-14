using afBounce

** Login - Fail
** ############
** 
** Example
** -------
** Assume I already have an account with the email address [micky.mouse@disney.com]`set:email` and password [password]`set:password`.
** 
** Given I'm on the [Login Page]`exe:showPage(#TEXT)`, when I enter the following wrong details:  
** 
**   table:
**   col[0]+set:input("#email").value
**   col[1]+set:input("#password").value
** 
**   Email                   password
**   ----------------------  --------
**   minny.mouse@disney.com  wotever
** 
** and click [Login]`exe:click("login")`
** then I should still see the [Login Page]`eq:renderedPageName` and the error message:
** 
**   eq:errorMsg
**   Email address not known
** 
class TestLoginFail : WebFixture {

	Uri? email
	Str? password {
		set { createOrUpdateUser(RepoUser(email, it)) }
	}
	
	Str errorMsg() {
		Element("form .alert-danger li:first-child").text
	}
}
