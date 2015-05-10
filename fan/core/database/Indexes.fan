using afIoc
using afMongo
using afMongo::User as MUser

const class Indexes {
	@Inject	private const Log log
	
	@Inject { type=RepoPod# } 
	private const Collection podCol

	@Inject { type=RepoUser# }
	private const Collection userCol
	
	new make(|This|in) { in(this) } 
	
	Void ensureIndexes() {
		log.info("Ensuring Mongo Indexes...")

		podCol.index("_name_")		.ensure(["name"		: Index.ASC])
		podCol.index("_ownerId_")	.ensure(["ownerId"	: Index.ASC])
		podCol.index("_isPublic_")	.ensure(["isPublic"	: Index.ASC])

		userCol.index("_email_")	.ensure(["email"	: Index.ASC])
		
		log.info("Done.")
	}
	
	Str:Obj? key() { Str:Obj?[:] { ordered = true } }
}
