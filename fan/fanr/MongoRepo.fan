using afIoc
using fanr
using fandoc
using afBedSheet

** My version of fanr::Repo - but with extra method params
const class MongoRepo {
	
	@Inject private const RepoPodDao		podDao
	@Inject private const RepoPodFileDao	podFileDao
	
	new make(|This|in) { in(this) }

	RepoPod? find(RepoUser? user, Str name, Version? version) {
//		user.filter(
			podDao.find(name, version)
//			)
	}

	RepoPod publish(RepoUser? user, File file) {
		// do this first as it throws an Err if meta.props does not exist
		podSpec := PodSpec.load(file)
		pod 	:= podDao.create(RepoPod(file, user))
		podFile	:= podFileDao.create(RepoPodFile(pod, file))
		return pod
	}

	PodSpec[] query(RepoUser? user, Str query, Int numVersions := 1) {
		if (numVersions < 1) throw ArgErr("numVersions < 1")
		
		q := Query.fromStr(query)
		
		pods := RepoPod[,] 
		podDao.query |c| {
			while (c.hasNext && pods.size < numVersions) {
				pod := podDao.toPod(c.next)
				if (q.include(pod.toPodSpec))
					pods.add(pod)
			}
			return null
		}
		
		return pods.map { it.toPodSpec }
	}
}
