using afIoc::Inject
using afMorphia::Datastore

const abstract class RepoUserDao : EntityDao {
	@Operator
	abstract RepoUser?		get(Int id, Bool checked := true)
	abstract RepoUser?		getByEmail(Str email, Bool checked := true)
	abstract RepoUser?		getByScreenName(Str screenName, Bool checked := true)
	abstract RepoUser[]		findAll()
	
	new make(|This| fn) : super(fn) { }
}

internal const class RepoUserDaoImpl : RepoUserDao {

	@Inject { type=RepoUser# }
	override const Datastore datastore
	
	new make(|This| fn) : super(fn) { }
	
	override RepoUser? get(Int id, Bool checked := true) {
		datastore.findOne(checked) { eq("_id", id) }
	}

	override RepoUser? getByEmail(Str email, Bool checked := true) {
		datastore.findOne(checked) { eqIgnoreCase("email", email.toStr) }
	}

	override RepoUser? getByScreenName(Str screenName, Bool checked := true) {
		datastore.findOne(checked) { eqIgnoreCase("screenName", screenName) }
	}

	override RepoUser[] findAll() {
		datastore.findAll("_email_")
	}
}
