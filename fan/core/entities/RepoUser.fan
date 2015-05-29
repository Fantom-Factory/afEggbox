using afIoc
using afMorphia
using afFormBean::HtmlInput
using afButter

@Entity { name = "user" }
class RepoUser {

	@Property{}	Int		_id
	
	@HtmlInput { type="static" }
	@Property{}	Uri		email
	
	@HtmlInput { type="text"; required=true; minLength=3; maxLength=128 }
	@Property{}	Str		screenName

	@HtmlInput { type="email"; minLength=3; maxLength=128 }
	@Property{}	Uri?	gravatarEmail
	
	@HtmlInput { type="text"; minLength=3; maxLength=128 }
	@Property{}	Str?	realName {
		set { &realName = it?.trimToNull }
	}

	@HtmlInput { type="textarea"; minLength=3; maxLength=2048 }
	@Property{}	Str?	aboutMe {
		set { &aboutMe = it?.trimToNull }
	}

	@Property{}	Str		userSalt
	@Property{}	Str		userSecret

	@Inject{} Fandoc?		fandocRenderer
	
	new make(|This| in) { in(this) }
	
	new makeNewUser(Uri email, Str password, |This|? f := null) {
		this.email 		= email
		this.userSalt	= Buf.random(16).toHex
		this.userSecret	= generateSecret(password)
		// see http://fantom.org/forum/topic/2415 for explanation of '//'
		this.screenName	= `//${email}`.userInfo?.replace(".", "_")?.toDisplayName ?: email.toStr.toDisplayName	// for tests where I can't be arsed to type in an entire email address
		f?.call(this)
	}
	
	Str generateSecret(Str password) {
		Buf().print("${email}:${userSalt}").hmac("SHA-1", password.toBuf).toBase64
	}
	
	Bool owns(RepoPod pod) {
		pod.ownerId == _id
	}
	
	Str aboutMeHtml() {
		fandocRenderer.writeStrToHtml(aboutMe, LinkResolverCtx())
	}
	
	Str gravatarImageUrl(Int size) {
		// identicon, monsterid, wavatar, retro
		`http://www.gravatar.com/avatar/${gravatarHash}`.plusQuery(["s":size.toStr, "d":"monsterid", "r":"x"]).encode
	}

	Uri gravatarJsonUri() {
		`http://www.gravatar.com/${gravatarHash}.json`
	}

	Str gravatarHash() {
		(gravatarEmail ?: email).encode.trim.lower.toBuf.toDigest("MD5").toHex
	}
	
	This populateFromGravatar() {
		butt := ButterDish(Butter.churnOut)
		butt.errOn4xx.enabled = false
		butt.errOn5xx.enabled = false
		req	 := ButterRequest(gravatarJsonUri)
		req.headers.userAgent = "afButter/1.1"	// required else Gravatar gives us the 403 finger
		res  := butt.sendRequest(req)
		if (res.statusCode == 200) {
			try {
			json := res.body.jsonMap
			name := json->get("entry")?->getSafe(0)?->get("name")?->get("formatted")
			abut := json->get("entry")?->getSafe(0)?->get("aboutMe")
			if (realName?.trimToNull == null)
				realName = name
			if (aboutMe?.trimToNull == null)
				aboutMe = abut
				
			} catch (Err err) {
				// I don't trust the gravatar API
				typeof.pod.log.warn("Could not parse Gravatar response for ${gravatarJsonUri}", err)
			}
		}
		return this
	}

	override Str toStr() { email.toStr }
	
	override Int hash() { _id }
	override Bool equals(Obj? that) {
		_id == (that as RepoUser)._id
	}
}
