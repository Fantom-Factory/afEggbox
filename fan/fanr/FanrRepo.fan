using afIoc
using fanr
using fandoc
using afBedSheet

** My version of fanr::Repo - but with extra method params
const class FanrRepo {
	const Int		maxPodSize	:= 10*1024*1024	// TODO: move 10 Mb max pod size to a config

	@Inject private const RepoUserDao		userDao
	@Inject private const RepoPodDao		podDao
	@Inject private const RepoPodFileDao	podFileDao
	@Inject private const RepoPodDocsDao	podDocsDao
	@Inject private const RepoPodSrcDao		podSrcDao
	@Inject private const RepoPodApiDao		podApiDao
	
	new make(|This|in) { in(this) }

	RepoPod? find(RepoUser? user, Str name, Version? version) {
		pod := podDao.findOne(name, version)
		if (pod == null)
			return null
		if (pod.isPublic)
			return pod
		if (user == null)
			return null
		return user.owns(pod) ? pod : null
	}

	** Throws 'PublishErr'
	RepoPod publish(RepoUser user, InStream podStream) {
	
		podContents := PodContents(user, podStream) { it.maxPodSize = this.maxPodSize }
		pod := podContents.pod
		
		// validate the pod before we publish it
		existing	:= podDao.findOne(pod.name)
		if (existing != null) {
			if (existing.ownerId != user._id) {
				exUser := userDao.get(existing.ownerId, false).userName
				throw PodPublishErr(Msgs.publish_podNameAlreadyTaken(pod.name, exUser))
			}
			
			if (pod.version <= existing.version)
				throw PodPublishErr(Msgs.publish_podVersionTooSmall(existing.version, pod.version))
		}
		
		if (pod.isPublic) {
			if (pod.meta.licenceName == null || pod.meta.licenceName.isEmpty)
				throw PodPublishErr(Msgs.publish_missingPublicPodMeta("licence.name' or 'license.name"))
			if ((pod.meta.vcsUrl == null || pod.meta.vcsUrl.toStr.isEmpty) && (pod.meta.orgUrl == null || pod.meta.orgUrl.toStr.isEmpty))
				throw PodPublishErr(Msgs.publish_missingPublicPodMeta("vcs.uri' or 'org.uri"))
		}	

		// all good - commit the data to the database
		pod 	 = podDao.create(pod)
		podFileDao.create(RepoPodFile(pod, podContents.podBuf))
		if (!podContents.docContents.isEmpty)
			podDocsDao.create(RepoPodDocs(pod, podContents.docContents))
		if (!podContents.srcContents.isEmpty)
			podSrcDao .create(RepoPodSrc (pod, podContents.srcContents))
		if (!podContents.apiContents.isEmpty)
			podApiDao .create(RepoPodApi (pod, podContents.apiContents))
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
	
	Void delete(RepoUser user, RepoPod pod) {
		// FIXME: make configurable
//		if (pod.isPublic)
//			throw PodDeleteErr(Msgs.podDelete_cannotDeletePublicPods(pod.name))

		if (!user.owns(pod))
			throw PodDeleteErr(Msgs.podDelete_cannotDeleteOtherPeoplesPods)

		podFileDao.deleteById(pod._id, false)
		podDocsDao.deleteById(pod._id, false)
		podSrcDao .deleteById(pod._id, false)
		podApiDao .deleteById(pod._id, false)
		podDao.delete(pod)
	}
}

class PodContents {
	Int		maxPodSize	:= 10*1024*1024	// TODO: move 10 Mb max pod size to a config

	Buf?	podBuf
	Str:Str	metaProps	:= Str:Str[:]
	Uri:Buf	docContents	:= Uri:Buf[:]
	Uri:Str	apiContents	:= Uri:Str[:]
	Uri:Str	srcContents	:= Uri:Str[:]
	RepoPod	pod
	
	
	new make(RepoUser user, InStream podStream, |This|? in := null) {
		in?.call(this)	// so we can override maxPodSize
		readPodStream(podStream)
		readPodContents
		
		if (metaProps.isEmpty)
			throw PodPublishErr(Msgs.publish_missingPodFile(`/meta.props`))

		pod = RepoPod(user, podBuf.size, metaProps, docContents)
		// Naa - we'll not enforce this, just print an embarrassing msg instead
//		if (pod.isPublic && !docContents.containsKey(`/doc/pod.fandoc`))
//			throw PodPublishErr(Msgs.publish_missingPublicPodFile(`/doc/pod.fandoc`))
		if (pod.name.size < 3)
			throw PodPublishErr(Msgs.publish_nameTooSmall(pod.name))
	}
	
	Void readPodStream(InStream podStream) {
		// attempt to read in the pod without blindly sucking in 19 Gigs!
		podBuf		= Buf(100 * 1024)	// Most pods are less than 100Kb
		bytesRead	:= (Int?) 0
		while (bytesRead != null && podBuf.size < maxPodSize) {
			// MultiPartInStream reads in chunks at a time
			bytesRead = podStream.readBuf(podBuf, maxPodSize - podBuf.size)
		}

		if (podBuf.size >= maxPodSize - 1)	// ensure there are no 'off by one' errors!
			throw PodPublishErr(Msgs.publish_podSizeTooBig(maxPodSize))

		podBuf.flip
	}
	
	private Void readPodContents() {
		zip	:= Zip.read(podBuf.in)
		try {
			File? entry
			while ((entry = zip.readNext) != null) {
				
				if (entry.uri == `/meta.props`)
					metaProps = entry.readProps
				
				if (entry.uri.toStr.startsWith("/doc/") && !entry.uri.isDir)
					if (entry.uri.path.size == 2 && entry.uri.ext == "apidoc")
						apiContents[entry.uri] = entry.readAllStr
					else
						docContents[entry.uri] = entry.readAllBuf
				
				if (entry.uri.toStr.startsWith("/src/") && entry.uri.ext == "fan" && !entry.uri.isDir)
					srcContents[entry.uri] = entry.readAllStr					
			}
		} finally {
			zip.close
		}	
	}
}

const class PodPublishErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}

const class PodDeleteErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}
