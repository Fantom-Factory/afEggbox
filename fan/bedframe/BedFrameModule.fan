using concurrent
using afIoc
using afIocConfig
using afIocEnv
using afBedSheet
using afEfanXtra
using afConcurrent::ActorPools

const class BedFrameModule {

	static Void defineServices(ServiceDefinitions defs) {
		defs.add(ErrEmailer#)
	}

	@Contribute { serviceType=ErrResponses# }
	static Void contributeErrResponses(Configuration config) {
		config[Err#] = MethodCall(ErrHandler#process).toImmutableFunc
	}

	@Contribute { serviceType=FileHandler# }
	static Void contributeFileHandler(Configuration config, Log log) {
		if (!`etc/web-static/`.toFile.exists) {
			
			tempFile := File.createTemp("afEggbox-", "-etc")
			dirName	 := tempFile.name
			tempFile.delete
			tempDir  := Env.cur.tempDir.createDir(dirName).deleteOnExit
			log.info("Copying 'web-static' files to: ${tempDir.normalize.osPath}")
			
			podFile := Env.cur.findPodFile(EggboxConfig#.pod.name)
			
			zip	:= Zip.read(podFile.in)
			try {
				File? entry
				while ((entry = zip.readNext) != null) {
					if (entry.uri.toStr.startsWith("/etc/web-static/")) {
						outFile := tempDir + entry.uri.relTo(`/etc/`)
						outFile.out(false, 4096).writeBuf(entry.readAllBuf).close
					}
				}
			} finally {
				zip.close
			}

			config[`/`] = tempDir + `web-static/` 
		} else
			config[`/`] = `etc/web-static/`
	}
	
	@Contribute { serviceType=TemplateDirectories# }
	static Void contributeEfanDirs(Configuration config) {
		addRecursive(config, `etc/web-pages/`.toFile)
		addRecursive(config, `etc/web-components/`.toFile)
	}

	@Contribute { serviceType=ActorPools# }
	static Void contributeActorPools(Configuration config) {
		config["afBedFrame.email"] = ActorPool() { it.maxThreads = 1; it.name="afBedFrame.email" }
	}

	@Contribute { serviceType=ApplicationDefaults# }
	static Void contributeApplicationDefaults(Configuration config) {
		config[BedSheetConfigIds.podHandlerBaseUrl] = null	// disable pod files
	}

	static Void addRecursive(Configuration config, File dir) {
		if (!dir.exists)
			return
		if (!dir.isDir) throw Err("`${dir.normalize}` is not a directory")
		dir.walk { if (it.isDir) config.add(it) }
	}
}
