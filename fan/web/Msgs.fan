
mixin Msgs {
	static Str login_incorrectDetails() {
		"Email and / or password incorrect"
	}
	
	static Str signup_emailTaken(Uri email) {
		"Email address `${email}` is already taken."
	}
}
