using afIoc
using afMorphia

@Entity { name = "user" }
class RepoUser {
	
//	@Property Str	_id
//	Uri	email {
//		get {  _id.toUri }
//		set {  _id = it.toStr }
//	}
		
//	@Property { name="_id" } Str	email
	@Property { name="_id" } Uri	email
	
//	@Property { }	Str?			userName
//	@Property { }	Str?			realName
	@Property { }	Str				userSalt
	@Property { }	Str				userSecret

	@Inject
	new make(|This| in) { in(this) }
	
	new makeNewUser(Uri email, Str password, |This|? f := null) {
		this.email 		= email
		this.userSalt	= Buf.random(16).toHex
		this.userSecret	= generateSecret(password)
//		this.userName	= email.userInfo
		f?.call(this)
	}
	
	Str generateSecret(Str password) {
		Buf().print("${email}:${userSalt}").hmac("SHA-1", password.toBuf).toBase64
	}
	
	RepoPod? filter(RepoPod pod) {
		pod.isPublic ? pod : (
			(pod.ownerId == email) ? pod : null
		)
	}
}
