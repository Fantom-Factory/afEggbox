
** Login - Success
** ###############
** 
** Example
** -------
** Assume I already have an account with the email address [micky.mouse@disney.com]`set:email` and password [password]`set:password`.
** 
** Given I'm on the [Login Page]`exe:showPage(#TEXT)`, when I enter the following details:  
** 
**   table:
**   col[0]+set:input("#email").value
**   col[1]+set:input("#password").value
** 
**   Email                   password
**   ----------------------  --------
**   micky.mouse@disney.com  password
** 
** and click [Login]`exe:click("login")`
** then I should be taken to the [My Pods Page]`eq:renderedPageName`.
class TestLoginSuccess : WebFixture {

	Str? email
	Str? password {
		set { createOrUpdateUser(RepoUser(email, it)) }
	}
}
