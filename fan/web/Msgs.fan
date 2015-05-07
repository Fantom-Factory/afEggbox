
mixin Msgs {
	static Str login_incorrectDetails() {
		"Email and / or password incorrect"
	}
	
	static Str signup_emailTaken(Uri email) {
		"Email address `${email}` is already taken."
	}
	
	// ---- Alert Messages ----------------------------------------------------
	
	static Str alert_userSignedUp(RepoUser user) {
		"Hi ${user.userName}, welcome the Fantom Pod Repository!"
	}
	
	static Str alert_userLoggedIn(RepoUser user) {
		"Welcome back ${user.userName}!"
	}

	static Str alert_userLoggedOut(RepoUser user) {
		"${user.userName} has left the building!"
	}

	static Str alert_userUploadedPod(RepoPod pod) {
		"${pod.displayName} was successfully uploaded!"
	}
}
