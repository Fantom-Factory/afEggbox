using afIoc
using afMorphia

const mixin RepoUserDao : EntityDao {
	@Operator
	abstract RepoUser?		get(Int id, Bool checked := true)
	abstract RepoUser?		getByEmail(Uri email, Bool checked := true)
	abstract RepoUser[]		findAll()
//	abstract RepoUser?		findByUsername(Str username)
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

	override RepoUser[] findAll() {
		datastore.query.orderBy("email").findAll
	}

//	override RepoUser? findByUsername(Str username) {
////		datastore.query(field(RepoUser#userName.name).eqIgnoreCase(username)).findOne(false)
//		datastore.query(field("_id").eqIgnoreCase(username)).findOne(false)
//	}

}
