using afIoc
using fanr::Repo as FanrRepo
using fanr
using fandoc

const class MongoRepo : FanrRepo {
	
	@Inject private const RepoPodDao		podDao
	@Inject private const RepoPodFileDao	podFileDao
	
	override const Uri uri := ``
	
	override const Str:Str ping := [
			"fanr.type":    MongoRepo#.pod.name,
			"fanr.version": Pod.find("fanr").version.toStr
		]

	new make(|This|in) { in(this) }
	
	override PodSpec publish(File file) {
		// do this first as it throws an Err if meta.props does not exist
		podSpec := PodSpec.load(file)
		pod 	:= podDao.create(RepoPod(file))
		podFile	:= podFileDao.create(RepoPodFile(pod, file))
		return podSpec
	}

	override InStream read(PodSpec pod) {
		throw Err("Not implemented")
	}

	override PodSpec? find(Str podName, Version? version, Bool checked := true) {
		throw UnknownPodErr()
	}

	override PodSpec[] query(Str query, Int numVersions := 1) {
		[,]
	}
}
