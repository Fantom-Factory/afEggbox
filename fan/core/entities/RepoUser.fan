using afIoc::Inject
using afMorphia::Entity
using afMorphia::BsonProp
using afFormBean::HtmlInput
using afButter::Butter
using afButter::ButterDish
using afButter::ButterRequest

@Entity { name = "user" }
class RepoUser {

	@BsonProp	Int		_id
	
	@HtmlInput { type="static" }
	@BsonProp	Str		email
	
	@HtmlInput { type="text"; required=true; minLength=3; maxLength=128 }
	@BsonProp	Str		screenName

	@HtmlInput { type="email"; minLength=3; maxLength=128 }
	@BsonProp	Str?	gravatarEmail
	
	@HtmlInput { type="text"; minLength=3; maxLength=128 }
	@BsonProp	Str?	realName {
		set { &realName = it?.trimToNull }
	}

	@HtmlInput { type="textarea"; minLength=3; maxLength=2048 }
	@BsonProp	Str?	aboutMe {
		set { &aboutMe = it?.trimToNull }
	}

	@BsonProp	Str		userSalt
	@BsonProp	Str		userSecret

	@Inject FandocWriter?		fandocRenderer
	@Inject EggboxConfig?		eggboxConfig
	@Inject RepoActivityDao?	activityDao
	
	new make(|This| in) { in(this) }
	
	new makeNewUser(Str email, Str password, |This|? f := null) {
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
		pod.ownerId == _id || isAdmin
	}
	
	Bool isAdmin() {
		eggboxConfig != null && (eggboxConfig.adminEnabled && eggboxConfig.adminEmail == email)
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
		(gravatarEmail ?: email).trim.lower.toBuf.toDigest("MD5").toHex
	}
	
	This populateFromGravatar() {
		butt := ButterDish(Butter.churnOut)
		butt.errOn4xx.enabled = false
		butt.errOn5xx.enabled = false
		try {
			req	 := ButterRequest(gravatarJsonUri)
			req.headers.userAgent = "afButter/1.1"	// required else Gravatar gives us the 403 finger
			res  := butt.sendRequest(req)
			if (res.statusCode == 200) {
				try {
					json := res.body.jsonMap
					enty := json->get("entry")?->getSafe(0)
					name := enty?->get("name")
					pref := (Bool) name?->isEmpty ? enty?->get("displayName") : name?->get("formatted")
					abut := enty?->get("aboutMe")
					if (realName?.trimToNull == null)
						realName = pref
					if (aboutMe?.trimToNull == null)
						aboutMe = abut
					
				} catch (Err err) {
					// I don't trust the gravatar API
					msg := "Could not parse Gravatar response for ${gravatarJsonUri}"
					activityDao.warn(msg, err, true)
				}
			}
		} catch (Err err) {
			// I don't trust external websites
			msg := "Could not contact Gravatar at ${gravatarJsonUri}"
			activityDao.warn(msg, err, true)
		}
		return this
	}

	override Str toStr() { email.toStr }
	
	override Int hash() { _id }
	override Bool equals(Obj? that) {
		_id == (that as RepoUser)?._id
	}
}
