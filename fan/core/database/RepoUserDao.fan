using afIoc
using afMorphia

const mixin RepoUserDao : EntityDao {
	@Operator
	abstract RepoUser?		get(Str name, Bool checked := true)
	abstract RepoUser[]		findAll()
	abstract RepoUser?		findByEmail(Uri email)
}

internal const class RepoUserDaoImpl : RepoUserDao {

	@Inject { type=RepoUser# }
	override const Datastore datastore
	
	@Inject
	override const IntSequences	intSeqs

	new make(|This| in) { in(this) }
	
	override RepoUser? get(Str name, Bool checked := true) {
		datastore.query(field("_id").eqIgnoreCase(name)).findOne(checked)
	}

	override RepoUser[] findAll() {
		datastore.query.orderBy("_id").findAll
	}

	override RepoUser? findByEmail(Uri email) {
		datastore.query(field("email").eqIgnoreCase(email.toStr)).findOne(false)
	}

	override RepoUser create(Obj user) {
		datastore.insert(user)
	}
}
