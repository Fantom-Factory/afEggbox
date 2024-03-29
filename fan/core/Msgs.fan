
mixin Msgs {

	// ---- Pod Publish Errors ------------------------------------------------

	static Str publish_podSizeTooBig(Int noOfBytes) {
		"Pod exceeds maximum size of " + noOfBytes.toLocale("B")
	}	

	static Str publish_podNameAlreadyTaken(Str podName, Str screenName) {
		"Pod name '${podName}' has already been taken by user '${screenName}'"
	}

	static Str publish_podVersionTooSmall(Version vOld, Version vNew) {
		"Pod version '${vNew}' must be greater than '${vOld}'"
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

	static Str publish_nameTooSmall(Str podName) {
		"Pod names must be at least 3 characters - ${podName}"
	}

	// ---- Pod Delete Errors -------------------------------------------------
	
	static Str podDelete_cannotDeletePublicPods(Str podName) {
		"Public pods may not be deleted"
	}
	
	static Str podDelete_cannotDeleteOtherPeoplesPods() {
		"You can not delete other people's pods!"
	}
	
	// ---- Form Errors -------------------------------------------------------

	static Str login_userNotFound() {
		"Email address not known"
	}
	
	static Str login_incorrectPassword() {
		"Incorrect password"
	}
	
	static Str signup_emailTaken(Str email) {
		"Email address `${email}` is already taken."
	}

	static Str userEdit_screenNameTaken(Str screenName) {
		"Screen name '${screenName}' has already been taken."
	}

	static Str podDelete_podNameDoesNotMatch(Str podName) {
		"The entered pod name was not '${podName}'"
	}
	
	// ---- Alert Messages ----------------------------------------------------
	
	static Str alert_userSignedUp(RepoUser user) {
		"Hi ${user.screenName}, welcome the Fantom Pod Repository!"
	}
	
	static Str alert_userLoggedIn(RepoUser user) {
		"Welcome back ${user.screenName}!"
	}

	static Str alert_userLoggedOut(RepoUser user) {
		"${user.screenName} has left the building!"
	}

	static Str alert_userUploadedPod(RepoPod pod) {
		"${pod.name} ${pod.version} was successfully uploaded!"
	}

	static Str alert_userDetailsSaved(RepoUser user) {
		"User details updated!"
	}

	static Str alert_podUpdated(RepoPod pod) {
		"Updated pod ${pod.name} ${pod.version}"
	}

	static Str alert_podDeleted(RepoPod pod) {
		"Deleted pod ${pod.name} ${pod.version}"
	}
}
