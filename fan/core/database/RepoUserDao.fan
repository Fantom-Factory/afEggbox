using afIoc
using afMorphia

const mixin RepoUserDao : EntityDao {
	@Operator
	abstract RepoUser?		get(Uri email, Bool checked := true)
	abstract RepoUser[]		findAll()
	abstract RepoUser?		findByEmail(Uri email)
//	abstract RepoUser?		findByUsername(Str username)
}

internal const class RepoUserDaoImpl : RepoUserDao {

	@Inject { type=RepoUser# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	new make(|This| in) { in(this) }
	
	override RepoUser? get(Uri email, Bool checked := true) {
		datastore.query(field("_id").eqIgnoreCase(email.toStr)).findOne(checked)
	}

	override RepoUser[] findAll() {
		datastore.query.orderBy("_id").findAll
	}

	override RepoUser? findByEmail(Uri email) {
		datastore.query(field(RepoUser#email.name).eqIgnoreCase(email.toStr)).findOne(false)
	}

//	override RepoUser? findByUsername(Str username) {
////		datastore.query(field(RepoUser#userName.name).eqIgnoreCase(username)).findOne(false)
//		datastore.query(field("_id").eqIgnoreCase(username)).findOne(false)
//	}

	override RepoUser create(Obj user) {
		datastore.insert(user)
	}
}
