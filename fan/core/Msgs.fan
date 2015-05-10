
mixin Msgs {

	// ---- Publish Errors ----------------------------------------------------

	static Str publish_podSizeTooBig(Int noOfBytes) {
		"Pod exceeds maximum size of " + noOfBytes.toLocale("B")
	}	

	static Str publish_podNameAlreadyTaken(Str podName, Str userName) {
		"Pod name '${podName}' has already been taken by user '${userName}'"
	}

	static Str publish_podVersionTooSmall(Version vOld, Version vNew) {
		"Pod version '${vNew}' is too small, it must be at least '${vOld}'"
	}

	static Str publish_missingPodMeta(Str metaName) {
		"Pods must define meta data for '${metaName}'"
	}

	static Str publish_missingPublicPodMeta(Str metaName) {
		"Public pods must define meta data for '${metaName}'"
	}

	static Str publish_missingPodFile(Uri fileUrl) {
		"Pods must contain the file `${fileUrl}`."
	}

	static Str publish_missingPublicPodFile(Uri fileUrl) {
		"Public pods must contain the file '${fileUrl}'."
	}

	// ---- Form Errors -------------------------------------------------------

	static Str login_userNotFound() {
		"Email address not known"
	}
	
	static Str login_incorrectPassword() {
		"Incorrect password"
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
