using afIoc::Inject
using afMongo::MongoColl
using afMongo::MongoIdx

const class Indexes {
	@Inject	private const Log log
	
	@Inject { type=RepoPod# } 
	private const MongoColl podCol

	@Inject { type=RepoUser# }
	private const MongoColl userCol

	@Inject { type=RepoActivity# }
	private const MongoColl activityCol

	@Inject { type=RepoPodDownload# }
	private const MongoColl podDownloadCol
	
	new make(|This|in) { in(this) } 
	
	Void ensureIndexes() {
		log.info("Ensuring Mongo Indexes...")

		if (!podCol.exists) podCol.create
		podCol.index("_ownerId_")		.ensure(["ownerId"						: MongoIdx.ASC])
		podCol.index("_podName_")		.ensure(["meta.pod\\u002ename"			: MongoIdx.ASC])
		podCol.index("_builtOn_")		.ensure(["meta.build\\u002ets"			: MongoIdx.DESC])
		podCol.index("_public_")		.ensure(["meta.repo\\u002epublic"		: MongoIdx.ASC])
		podCol.index("_deprecated_")	.ensure(["meta.repo\\u002edeprecated"	: MongoIdx.ASC])

		if (!userCol.exists) userCol.create
		userCol.index("_email_")		.ensure(["email"		: MongoIdx.ASC], true)
		userCol.index("_screenName_")	.ensure(["screenName"	: MongoIdx.ASC], true)
		
		if (!activityCol.exists) activityCol.create
		activityCol.index("_userId_")	.ensure(["userId"		: MongoIdx.ASC])
		activityCol.index("_when_")		.ensure(["when"			: MongoIdx.DESC])
		
		if (!podDownloadCol.exists) podDownloadCol.create
		podDownloadCol.index("_pod_")	.ensure(["pod"			: MongoIdx.ASC])
		podDownloadCol.index("_when_")	.ensure(["when"			: MongoIdx.DESC])
		
		// we can't run mapReduce commands on a collection that doesn't exist
		// i.e. the /pods page throws a MongoDB Err if there are no pods
		if (!podCol.exists) podCol.create
		
		log.info("Done.")
	}
	
	Str:Obj? key() { Str:Obj?[:] { ordered = true } }
}

