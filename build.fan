using build
using fanr

class Build : BuildPod {

	new make() {
		podName = "afPodRepo"
		summary = "Fantom Pod Repository"
		version = Version("0.0.1")

		meta = [
			"proj.name"		: "Fantom Pod Repository",
			"afIoc.module"	: "afPodRepo::CoreModule",
			"internal"		: "true",
			"tags"			: "app",
			"repo.private"	: "true"
		]

		depends = [
			"sys          1.0.67 - 1.0",
			"concurrent   1.0.67 - 1.0",
			"fanr         1.0.67 - 1.0",
			"fandoc       1.0.67 - 1.0",
			"email        1.0.67 - 1.0",

			// ---- Core ------------------------
			"afBeanUtils  1.0.4  - 1.0", 
			"afConcurrent 1.0.8  - 1.0", 
			"afIoc        2.0.6  - 2.0", 
			"afIocConfig  1.0.16 - 1.0", 
			"afIocEnv     1.0.18 - 1.0", 
			
			// ---- Database --------------------
			"afBson       1.0.0  - 1.0",
			"afMongo      1.0.3  - 1.0",
			"afMorphia    1.0.2  - 1.0",
			
			// ---- Web -------------------------
			"afBedSheet   1.4.8  - 1.4",
			"afEfanXtra   1.1.2  - 1.1",
			"afPillow     1.0.22 - 1.0",
			"afDuvet      1.0.8  - 1.0",
			"afSlim       1.1.16 - 1.1",
			"afFormBean   0+",
			"afColdFeet   1.3.4  - 1.3",
			"afSitemap    1.0.0  - 1.0",

			"syntax       1.0.67 - 1.0",
			"web          1.0.67 - 1.0",

			// ---- Test ------------------------
			"util         1.0.67 - 1.0",
			"afBounce     1.0.20 - 1.0",
			"afButter     1.1.2  - 1.1",
			"afFancordion 1.0.0  - 1.0"
		]

		srcDirs = [`test-spec/`, `test-spec/web/`, `test-spec/web/login/`, `test-spec/utils/`, `test-spec/fanr/`, `test-spec/core/`, `fan/`, `fan/web/`, `fan/web/util/`, `fan/web/services/`, `fan/web/pages/`, `fan/web/pages/pods/`, `fan/web/pages/my/`, `fan/web/pages/help/`, `fan/web/components/`, `fan/web/components/fandoc/`, `fan/fanr/`, `fan/fandoc/`, `fan/fandoc/internal/`, `fan/fanapi/`, `fan/fanapi/model/`, `fan/core/`, `fan/core/entities/`, `fan/core/database/`, `fan/bedframe/`]
		resDirs = [`res/`, `test/res/`]
	}
	
	
	@Target { help = "Heroku pre-compile hook, use to install dependencies" }
	Void herokuPreCompile() {

		pods := depends.findAll |Str dep->Bool| {
			depend := Depend(dep)
			pod := Pod.find(depend.name, false)
			return (pod == null) ? true : !depend.match(pod.version)
		}
		installFromRepo(pods, "http://repo.status302.com/fanr/") // repo = "file:lib/fanr/"

		// patch web font mime types
		patchMimeTypes([
			"eot"	: "application/vnd.ms-fontobject",
			"otf"	: "application/font-sfnt",
			"svg"	: "image/svg+xml",
			"ttf"	: "application/font-sfnt",
			"woff"	: "application/font-woff"
		])
	}

	private Void installFromRepo(Str[] pods, Str repo) {
		cmd := "install -errTrace -y -r ${repo}".split.add(pods.join(","))
		log.info("")
		log.info("Installing pods...")
		log.indent
		log.info("> fanr " + cmd.join(" ") { it.containsChar(' ') ? "\"$it\"" : it })
		status := fanr::Main().main(cmd)
		log.unindent
		// abort build if something went wrong
		if (status != 0) Env.cur.exit(status)

		(scriptDir + `lib-fan/afBedSheet.pod`).copyInto(devHomeDir + `lib/fan/`, ["overwrite" : true])
		(scriptDir + `lib-fan/afFormBean.pod`).copyInto(devHomeDir + `lib/fan/`, ["overwrite" : true])
	}

	private Void patchMimeTypes(Str:Str extToMimeTypes) {
		ext2mime := Env.cur.findFile(`etc/sys/ext2mime.props`)
		mimeTypes := ext2mime.readProps
		
		toAdd := extToMimeTypes.exclude |mime, ext->Bool| {
			mimeTypes.containsKey(ext)
		}
		
		if (!toAdd.isEmpty) {
			log.indent
			exts := toAdd.keys.sort.join(", ")
			log.info("Mime type for file extension(s) ${exts} do not exist")
			log.info("Patching `${ext2mime.normalize}`...")
			toAdd.keys.sort.each |ext| {
				mimeTypes = mimeTypes.rw.add(ext, extToMimeTypes[ext])
				log.info("   ${ext} = " + mimeTypes[ext])
			}
			ext2mime.writeProps(mimeTypes)
			log.info("Done.")
			log.unindent
		}
	}
}
