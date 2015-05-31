using afIoc
using afMongo
using afMongo::User as MUser

const class Indexes {
	@Inject	private const Log log
	
	@Inject { type=RepoPod# } 
	private const Collection podCol

	@Inject { type=RepoUser# }
	private const Collection userCol

	@Inject { type=RepoPodDownload# }
	private const Collection podDownloadCol
	
	new make(|This|in) { in(this) } 
	
	Void ensureIndexes() {
		log.info("Ensuring Mongo Indexes...")

		podCol.index("_name_")			.ensure(["name"			: Index.ASC])
		podCol.index("_ownerId_")		.ensure(["ownerId"		: Index.ASC])
		podCol.index("_builtOn_")		.ensure(["builtOn"		: Index.DESC])
		podCol.index("_isPublic_")		.ensure(["isPublic"		: Index.ASC])
		podCol.index("_isDeprecated_")	.ensure(["isDeprecated"	: Index.ASC])

		userCol.index("_email_")		.ensure(["email"		: Index.ASC])
		
		podDownloadCol.index("_when_")	.ensure(["when"			: Index.ASC])
		
		// we can't run mapReduce commands on a collection that doesn't exist
		// i.e. the /pods page throws a MongoDB Err if there are no pods
		if (!podCol.exists)
			podCol.create
		
		log.info("Done.")
	}
	
	Str:Obj? key() { Str:Obj?[:] { ordered = true } }
}
