using afIoc
using fanr

const class MongoRepoAuth : WebRepoAuth {

	@Inject private const RepoUserDao	userDao
			override const Str[]		secretAlgorithms	:= ["SALTED-HMAC-SHA1"]

	new make(|This|in) { in(this) }
	
	override Obj? user(Str username) {
		userDao.get(username, false)
	}
	
	override Str? salt(Obj? userObj) {
		((RepoUser?) userObj)?.userSalt
	}

	override Buf secret(Obj? userObj, Str algorithm) {
		if (algorithm != "SALTED-HMAC-SHA1")
			throw Err("Unexpected secret algorithm: $algorithm")
		user := (RepoUser?) userObj
		return Buf.fromBase64(user.userSecret)
	}

	override Bool allowQuery(Obj? u, PodSpec? p) { true }
	
	override Bool allowRead	(Obj? u, PodSpec? p) { true }
	
	override Bool allowPublish(Obj? user, PodSpec? podSpec) { user is RepoUser }

}
