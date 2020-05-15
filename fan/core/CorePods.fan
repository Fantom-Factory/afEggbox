using afBeanUtils
using afConcurrent

const class CorePods {
	private const AtomicMap	coreDepends		:= AtomicMap() { it.keyType=Str#; it.valType=Depend[]# }
	private const Str[]		corePodNames	:= "docIntro docLang docFanr docTools build compiler compilerDoc compilerJava compilerJs concurrent dom domkit email fandoc fanr fansh flux fluxText fwt gfx icons inet obix sql syntax sys testCompiler testJava testNative testSys util web webfwt webmod wisp xml".split

	Bool isCorePod(Str podName) {
		corePodNames.any { it.equalsIgnoreCase(podName) }
	}

	// caters for Uri.scheme lower casing stuff!
	Str corePodName(Str podName) {
		corePodNames.find { it.equalsIgnoreCase(podName) } ?: throw ArgNotFoundErr("Could not find core pod '${podName}'", corePodNames)
	}
	
	// FIXME - we don't deploy with ALL core pods - so maybe generate this dependency list on build?
	Depend[] depends(Str podName) {
		coreDepends.getOrAdd(podName) |->Depend[]| {
			podFile		:= Env.cur.findPodFile(podName)
			if (podFile != null) {
				zip			:= Zip.read(podFile.in(4096))
				metaProps	:= null as Str:Str
				try {
					File? entry
					while (metaProps == null && (entry = zip.readNext) != null) {
						if (entry.uri == `/meta.props`)
							metaProps = entry.readProps
					}
				} finally {
					zip.close
				}
				// null checks 'cos sys has no dependencies!
				return metaProps?.get("pod.depends")?.split(';')?.map |d->Depend?| { Depend(d, false) }?.exclude { it == null } ?: Depend#.emptyList
			} else {
				CorePods#.pod.log.warn("Core pod $podName does not exist")
				return Depend#.emptyList
			}
		}
	}
}

