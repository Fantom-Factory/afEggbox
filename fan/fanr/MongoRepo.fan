using afIoc
using fanr::Repo as FanrRepo
using fanr
using fandoc

const class MongoRepo {
	
	@Inject private const RepoPodDao		podDao
	@Inject private const RepoPodFileDao	podFileDao
	
	const Str:Str ping := [
			"fanr.type":    MongoRepo#.pod.name,
			"fanr.version": Pod.find("fanr").version.toStr
		]

	new make(|This|in) { in(this) }
	
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

	PodSpec? find(Str podName, Version? version, Bool checked := true) {
		throw UnknownPodErr()
	}

	PodSpec[] query(Str query, Int numVersions := 1) {
		[,]
	}
}
