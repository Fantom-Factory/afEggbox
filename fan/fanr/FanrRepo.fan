using afIoc
using fanr
using fandoc
using afBedSheet

** My version of fanr::Repo - but with extra method params
const class FanrRepo {
	
			private const Int				maxPodSize	:= 10*1024*1024	// TODO: move 10 Mb max pod size to a config
	@Inject private const RepoPodDao		podDao
	@Inject private const RepoPodFileDao	podFileDao
	
	new make(|This|in) { in(this) }

	RepoPod? find(RepoUser? user, Str name, Version? version) {
//		user.filter(
			podDao.find(name, version)
//			)
	}

	** Throws 'PublishErr'
	RepoPod publish(RepoUser? user, InStream podStream) {
		podBuf		:= Buf(100 * 1024)	// Most pods are less than 100Kb
		bytesRead	:= (Int?) 0
		while (bytesRead != null && podBuf.size < maxPodSize) {
			// MultiPartInStream reads in chunks at a time
			bytesRead = podStream.readBuf(podBuf, maxPodSize - podBuf.size)
		}
		if (podBuf.size >= maxPodSize - 1)	// ensure there are no 'off by one' errors!
			throw PublishErr("Pod exceeds maximum size of " + maxPodSize.toLocale("B"))
		pod 	:= podDao.create(RepoPod(user, podBuf.flip))
		podFile	:= podFileDao.create(RepoPodFile(pod, podBuf))
		return pod
	}

	RepoPod[] query(RepoUser? user, Str query, Int numVersions := 1) {
		if (numVersions < 1) throw ArgErr("numVersions < 1")
		
		q := Query.fromStr(query)
		
		return podDao.query |c| {
			pods := RepoPod[,] 
			while (c.hasNext && pods.size < numVersions) {
				pod := podDao.toPod(c.next)
				if (q.include(pod.toPodSpec))
					pods.add(pod)
			}
			return pods
		}
	}
}

const class PublishErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}