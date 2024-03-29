using afIoc::Inject
using afIoc::Scope
using fanr
using fandoc
using afBedSheet

** My version of fanr::Repo - but with extra method params
const class FanrRepo {
	const Int		maxPodSize	:= 10*1024*1024	// TODO move 10 Mb max pod size to a config

	@Inject private const RepoUserDao		userDao
	@Inject private const RepoPodDao		podDao
	@Inject private const RepoPodFileDao	podFileDao
	@Inject private const RepoPodDocsDao	podDocsDao
	@Inject private const RepoPodSrcDao		podSrcDao
	@Inject private const RepoPodApiDao		podApiDao
	@Inject private const Scope				scope
	@Inject	private const RepoActivityDao	activityDao
	
	new make(|This|in) { in(this) }

	RepoPod? find(RepoUser? user, Str name, Version? version) {
		pod := podDao.findPod(name, version)
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
		existing	:= podDao.findPod(pod.name)
		if (existing != null) {
			if (existing.ownerId != user._id) {
				exUser := userDao.get(existing.ownerId, false).screenName
				throw PodPublishErr(Msgs.publish_podNameAlreadyTaken(pod.name, exUser))
			}
			
			// it makes life easier if we just let admins (i.e. ME!) do what they want
			if (pod.version <= existing.version && !user.isAdmin)
				throw PodPublishErr(Msgs.publish_podVersionTooSmall(existing.version, pod.version))
		}
		
		if (pod.isPublic) {
			errs := pod.validateForPublicUse
			if (errs.size > 0)
				throw PodPublishErr(errs.first)
		}

		podDocs := RepoPodDocs(pod, podContents.docContents)
		podApi	:= RepoPodApi (pod, podContents.apiContents)
		podSrc	:= RepoPodSrc (pod, podContents.srcContents, podApi.srcDocs)
		pod.hasApi = !podApi.allTypes.isEmpty
		
		// all good - commit the data to the database
		pod = podDao.create(pod)
		podFileDao.create(RepoPodFile(pod, podContents.podBuf))
		if (!podContents.docContents.isEmpty)
			podDocsDao.create(podDocs)
		if (!podApi.allTypes.isEmpty)
			podApiDao .create(podApi)
		if (!podSrc.isEmpty)
			podSrcDao .create(podSrc)
		scope.inject(pod)
		pod.validateDocumentLinks.save

		activityDao.create(RepoActivity(user, pod, LogMsgs.publishedPod, pod._id))
		return pod
	}

	RepoPod[] query(RepoUser? user, Str query, Int numVersions := 1) {
		if (numVersions < 1) throw ArgErr("numVersions < 1")
		
		// a quick speed hack - fanr (when installing) uses query not find, so we re-route it!
		if (query.trim.all { it.isAlphaNum })
			return podDao.findPodVersions(query.trim, numVersions)

		// another speed hack - for when looking for a specific pod
		podName := (Str?) null
		depend  := Depend(query.trim, false) 
		if (depend != null) {
			podName = depend.name
			// need to match 0.0 against 0.0.2, and find latest for 2.0.7 - 2.0
//			pod := podDao.findPod(nom, ver)
//			return pod != null ? [pod] : RepoPod[,] 
		}

		// speed hacks for globs is tricy, 'cos we still have numVersions to honour
		// we can't just search the latest pods
		// TODO have reduceByVersion() / aggregation return a customisable number of pod versions 
		
		c := podDao.doQuery(podName)
		q := Query.fromStr(query)
		
		pods := Str:RepoPod[][:] 
		try while (c.isAlive) {
			doc := c.next
			if (doc == null) break
			pod := podDao.toPod(doc)
			if ((pods[pod.name]?.size ?: 0) < numVersions)
				if (pod.isPublic || (user != null && user.owns(pod)))
					if (q.include(pod.toPodSpec))
						pods.getOrAdd(pod.name) { RepoPod[,] }.add(pod)
		}
		finally c.kill
		return pods.vals.flatten
	}
		
	Void delete(RepoUser user, RepoPod pod) {
		// TODO make deleting public pods configurable
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
	Int		maxPodSize	:= 10*1024*1024	// TODO move 10 Mb max pod size to a config

	Buf?	podBuf
	Str:Str	metaProps	:= Str:Str[:]
	Uri:Buf	docContents	:= Uri:Buf[:]
	Uri:Str	apiContents	:= Uri:Str[:]
	Uri:Str	srcContents	:= Uri:Str[:]
	Str[]	rootFileNames := Str[,]
	RepoPod	pod
	
	
	new make(RepoUser user, InStream podStream, |This|? in := null) {
		in?.call(this)	// so we can override maxPodSize
		readPodStream(podStream)
		readPodContents
		
		if (metaProps.isEmpty)
			throw PodPublishErr(Msgs.publish_missingPodFile(`/meta.props`))

		pod = RepoPod(user, podBuf.size, metaProps, docContents, rootFileNames)
		
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
				
				if (entry.uri.path.size == 1)
					rootFileNames.add(entry.uri.name)
				
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
