using afBounce

** Sign Up
** #######
** 
** Example
** -------
** Given I'm on the [Signup Page]`exe:showPage(#TEXT)`, when I enter the following data:
** 
**   table:
**   col[0]+set:input("#email").value
**   col[1]+set:input("#password").value
** 
**   Email                   password
**   ----------------------  --------
**   micky.mouse@disney.com  password
** 
** and click [Sign Up]`exe:clickSignUp`
** then a new user should be saved to the database with the values:
** 
**   table:
**   col[0]+eq:user.email
** 
**   Email 
**   ----  
**   micky.mouse@disney.com 
** 
** On signing up I should be taken to the [user details page]`eq:renderedPageName` and see the message:
** 
**   eq:flashMsg
**   Quote by 'ED 209' was successfully created
class TestSignUp : WebFixture {
	
	Void clickSignUp() {
		SubmitButton("[name=signUp]").submitForm
	}

	RepoUser user() {
		userDao.findAll.first
	}
}
