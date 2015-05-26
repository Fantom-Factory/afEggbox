using afIoc
using afMorphia

const mixin RepoUserDao : EntityDao {
	@Operator
	abstract RepoUser?		get(Int id, Bool checked := true)
	abstract RepoUser?		getByEmail(Uri email, Bool checked := true)
	abstract RepoUser?		getByScreenName(Str screenName, Bool checked := true)
	abstract RepoUser[]		findAll()
}

internal const class RepoUserDaoImpl : RepoUserDao {

	@Inject { type=RepoUser# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	new make(|This| in) { in(this) }
	
	override RepoUser? get(Int id, Bool checked := true) {
		datastore.query(field("_id").eq(id)).findOne(checked)
	}

	override RepoUser? getByEmail(Uri email, Bool checked := true) {
		datastore.query(field("email").eqIgnoreCase(email.toStr)).findOne(checked)
	}

	override RepoUser? getByScreenName(Str screenName, Bool checked := true) {
		datastore.query(field("screenName").eqIgnoreCase(screenName)).findOne(checked)
	}

	override RepoUser[] findAll() {
		datastore.query.orderBy("email").findAll
	}
}
