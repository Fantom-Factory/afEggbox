using fanr

const class MongoRepoAuth : WebRepoAuth {
	override Obj? user(Str username) { null }
	override Str? salt(Obj? user) { publicSalt }
	override Buf secret(Obj? user, Str algorithm) { Buf() }
	override Str[] secretAlgorithms() { ["PASSWORD", "SALTED-HMAC-SHA1"] }
	override Bool allowQuery(Obj? u, PodSpec? p) { true }
	override Bool allowRead(Obj? u, PodSpec? p)   { true }
	override Bool allowPublish(Obj? u, PodSpec? p) { true }

	private const Str publicSalt := Buf.random(16).toHex
}
