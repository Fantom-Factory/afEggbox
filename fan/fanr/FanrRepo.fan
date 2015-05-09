using afIoc
using fanr
using fandoc
using afBedSheet

** My version of fanr::Repo - but with extra method params
const class FanrRepo {
	
			internal const Int				maxPodSize	:= 10*1024*1024	// TODO: move 10 Mb max pod size to a config
	@Inject private const RepoUserDao		userDao
	@Inject private const RepoPodDao		podDao
	@Inject private const RepoPodFileDao	podFileDao
	
	new make(|This|in) { in(this) }

	RepoPod? find(RepoUser? user, Str name, Version? version) {
		podDao.findOne(name, version)
	}

	** Throws 'PublishErr'
	RepoPod publish(RepoUser user, InStream podStream) {
		// attempt to read in the pod without blindly sucking in 19 Gigs!
		podBuf		:= Buf(100 * 1024)	// Most pods are less than 100Kb
		bytesRead	:= (Int?) 0
		while (bytesRead != null && podBuf.size < maxPodSize) {
			// MultiPartInStream reads in chunks at a time
			bytesRead = podStream.readBuf(podBuf, maxPodSize - podBuf.size)
		}
		if (podBuf.size >= maxPodSize - 1)	// ensure there are no 'off by one' errors!
			throw PublishErr(Msgs.publish_podSizeTooBig(maxPodSize))

		// validate the pod before we publish it
		pod 		:= RepoPod(user, podBuf.flip)
		existing	:= podDao.findMany(pod.name).first
		if (existing != null) {
			if (existing.ownerId != user.email) {
				exUser := userDao.get(existing.ownerId, false)?.userName ?: `//${existing.ownerId}`.userInfo
				throw PublishErr(Msgs.publish_podNameAlreadyTaken(pod.name, exUser))
			}
			
			if (pod.version <= existing.version)
				throw PublishErr(Msgs.publish_podVersionTooSmall(existing.version, pod.version))
		}
		
		if (pod.isPublic) {
			if (pod.meta.licenceName == null)
				throw PublishErr(Msgs.publish_missingPublicPodMeta("licence.name' or 'license.name"))
			if (pod.meta.vcsUrl == null && pod.meta.orgUrl == null)
				throw PublishErr(Msgs.publish_missingPublicPodMeta("vcs.uri' or 'org.uri"))
		}
		
		// all good - commit the data to the database
		pod 	 = podDao.create(pod)
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