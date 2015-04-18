using afIoc
using fanr::Repo as FanrRepo
using fanr
using fandoc

** My version of fanr::Repo - but with extra method params
const class MongoRepo {
	
	@Inject private const RepoPodDao		podDao
	@Inject private const RepoPodFileDao	podFileDao
	
	const Str:Str ping := [
			"fanr.type"		: MongoRepo#.qname,
			"fanr.version"	: Pod.find("fanr").version.toStr
		]

	new make(|This|in) { in(this) }

	PodSpec? find(Str podName, Version? podVersion, Bool checked := true) {
		podDao.find(podName, podVersion, checked).toPodSpec
	}

	PodSpec publish(File file, RepoUser user) {
		// do this first as it throws an Err if meta.props does not exist
		podSpec := PodSpec.load(file)
		pod 	:= podDao.create(RepoPod(file, user))
		podFile	:= podFileDao.create(RepoPodFile(pod, file))
		return podSpec
	}

	InStream read(PodSpec pod) {
		throw Err("Not implemented")
	}

	PodSpec[] query(Str query, Int numVersions := 1) {
		[,]
	}
}
