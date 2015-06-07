using afIoc
using afMongo
using afMongo::User as MUser

const class Indexes {
	@Inject	private const Log log
	
	@Inject { type=RepoPod# } 
	private const Collection podCol

	@Inject { type=RepoUser# }
	private const Collection userCol

	@Inject { type=RepoActivity# }
	private const Collection activityCol

	@Inject { type=RepoPodDownload# }
	private const Collection podDownloadCol
	
	new make(|This|in) { in(this) } 
	
	Void ensureIndexes() {
		log.info("Ensuring Mongo Indexes...")

		podCol.index("_ownerId_")		.ensure(["ownerId"						: Index.ASC])
		podCol.index("_podName_")		.ensure(["meta.pod\\u002ename"			: Index.ASC])
		podCol.index("_projName_")		.ensure(["meta.proj\\u002ename"			: Index.ASC])
		podCol.index("_builtOn_")		.ensure(["meta.build\\u002ets"			: Index.DESC])
		podCol.index("_public_")		.ensure(["meta.repo\\u002epublic"		: Index.ASC])
		podCol.index("_deprecated_")	.ensure(["meta.repo\\u002edeprecated"	: Index.ASC])

		userCol.index("_email_")		.ensure(["email"		: Index.ASC], true)
		userCol.index("_screenName_")	.ensure(["screenName"	: Index.ASC], true)
		
		activityCol.index("_userId_")	.ensure(["userId"		: Index.ASC])
		activityCol.index("_when_")		.ensure(["when"			: Index.DESC])
		
		podDownloadCol.index("_podId_")	.ensure(["podId"		: Index.ASC])
		podDownloadCol.index("_when_")	.ensure(["when"			: Index.DESC])
		
		// we can't run mapReduce commands on a collection that doesn't exist
		// i.e. the /pods page throws a MongoDB Err if there are no pods
		if (!podCol.exists)
			podCol.create
		
		log.info("Done.")
	}
	
	Str:Obj? key() { Str:Obj?[:] { ordered = true } }
}

