using afIoc
using afMorphia
using afFormBean::HtmlInput

@Entity { name = "user" }
class RepoUser {

	@Property { }	Int		_id
	
	@HtmlInput { type="static" }
	@Property  { }	Uri		email
	
	@HtmlInput { type="text"; required=true; minLength=3; maxLength=128 }
	@Property  { }	Str		userName

	@Property { }	Str		userSalt
	@Property { }	Str		userSecret

	new make(|This| in) { in(this) }
	
	new makeNewUser(Uri email, Str password, |This|? f := null) {
		this.email 		= email
		this.userSalt	= Buf.random(16).toHex
		this.userSecret	= generateSecret(password)
		// see http://fantom.org/forum/topic/2415 for explanation of '//'
		this.userName	= `//${email}`.userInfo?.replace(".", "_")?.toDisplayName ?: email.toStr.toDisplayName	// for tests where I can't be arsed to type in an entire email address
		f?.call(this)
	}
	
	Str generateSecret(Str password) {
		Buf().print("${email}:${userSalt}").hmac("SHA-1", password.toBuf).toBase64
	}
	
	Bool owns(RepoPod pod) {
		pod.ownerId == _id
	}
	
	override Str toStr() { email.toStr }
}
