using build
using compiler
using fanr

class Build : BuildPod {

	new make() {
		podName = "afEggbox"
		summary = "A website for uploading, viewing, and downloading Fantom pods. Host your very own Pod Repository!"
		version = Version("0.1.3")

		meta = [
			"pod.dis"		: "Eggbox",
			"afIoc.module"	: "afEggbox::CoreModule",
			"repo.tags"		: "app",
			"repo.public"	: "true"
		]

		depends = [
			"sys          1.0.69 - 1.0",
			"concurrent   1.0.69 - 1.0",
			"fanr         1.0.69 - 1.0",
			"fandoc       1.0.69 - 1.0",
			"email        1.0.69 - 1.0",

			// ---- Core ------------------------
			"afBeanUtils  1.0.8  - 1.0", 
			"afConcurrent 1.0.14 - 1.0", 
			"afIoc        3.0.4  - 3.0", 
			"afIocConfig  1.1.0  - 1.1", 
			"afIocEnv     1.1.0  - 1.1", 
			
			// ---- Database --------------------
			"afBson       1.0.0  - 1.0",
			"afMongo      1.0.8  - 1.0",
			"afMorphia    1.1.0  - 1.1",
			
			// ---- Web -------------------------
			"afBedSheet   1.5.2  - 1.5",
			"afEfanXtra   1.2.0  - 1.2",
			"afPillow     1.1.2  - 1.1",
			"afDuvet      1.1.2  - 1.1",
			"afSlim       1.2.0  - 1.2",
			"afFormBean   1.1.4  - 1.1",
			"afColdFeet   1.4.0  - 1.4",
			"afSitemap    1.1.0  - 1.1",
			"afGoogleAnalytics 0.1.4 - 0.1",
			"afAtom       1.0.2  - 1.0",

			// ---- Other -----------------------
			"afButter     1.2.2  - 1.2",
			"afPegger     0.1.0  - 0.1",
			"syntax       1.0.69 - 1.0",
			"util         1.0.69 - 1.0",
			"web          1.0.69 - 1.0",
			"xml          1.0.69 - 1.0",

			// ---- Test ------------------------
			"afBounce     1.1.2  - 1.1",
			"afFancordion 1.1.2  - 1.1",
			"afFancordionBootstrap 1.0.2 - 1.0"
		]

		srcDirs = [`fan/`, `fan/bedframe/`, `fan/core/`, `fan/core/database/`, `fan/core/entities/`, `fan/fanapi/`, `fan/fanapi/model/`, `fan/fandoc/`, `fan/fandoc/internal/`, `fan/fanr/`, `fan/web/`, `fan/web/components/`, `fan/web/components/fandoc/`, `fan/web/pages/`, `fan/web/pages/help/`, `fan/web/pages/my/`, `fan/web/pages/pods/`, `fan/web/services/`, `fan/web/util/`, `test/`, `test/res/`, `test-spec/`, `test-spec/core/`, `test-spec/fanr/`, `test-spec/utils/`, `test-spec/web/`, `test-spec/web/login/`]
		resDirs = [`doc/`, `res/`, `test/res/`]
		
		docApi	= false
		docSrc	= false

		meta["afBuild.docApi"]		= "false"
		meta["afBuild.docSrc"]		= "false"
		meta["afBuild.testPods"]	= "afBounce afFancordion afFancordionBootstrap"
		meta["afBuild.testDirs"]	= "test/ test-spec/"
	}

	override Void onCompileFan(CompilerInput ci) {
		if (ci.resFiles == null)
			ci.resFiles = Uri[,]
		addRecursive(ci.resFiles, `etc/web-components/`.toFile)
		addRecursive(ci.resFiles, `etc/web-pages/`.toFile)
		addRecursive(ci.resFiles, `etc/web-static/`.toFile)
	}
	
	@Target { help = "Heroku pre-compile hook, use to install dependencies" }
	Void herokuPreCompile() {

		pods := depends.findAll |Str dep->Bool| {
			depend := Depend(dep)
			pod := Pod.find(depend.name, false)
			return (pod == null) ? true : !depend.match(pod.version)
		}
		installFromRepo(pods, "http://eggbox.fantomfactory.org/fanr/")

		patchMimeTypes([
			"eot"	: "application/vnd.ms-fontobject",
			"otf"	: "application/font-sfnt",
			"svg"	: "image/svg+xml",
			"ttf"	: "application/font-sfnt",
			"woff"	: "application/font-woff"
		])
		
		installFandocSyntaxFile
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
	
	private Void installFandocSyntaxFile() {
		etcUri	:= `etc/syntax/syntax-fandoc.fog`
		etcFile := Env.cur.findFile(etcUri, false)

		// copy over syntax-fandoc.fog
		if (etcFile == null) {
			etcFile = (Env.cur.workDir + etcUri).normalize
			podFile	:= `res/syntax-fandoc.fog`.toFile
			
			try {
				podFile.copyTo(etcFile)
				log.info("Installed fandoc syntax file to: ${etcFile}")
			} catch (Err err) {
				log.warn("Could not copy syntax file to: ${etcFile} - ${err.typeof.qname} - ${err.msg}")
				return	// abandon installation - if the syntax file doesn't exist, don't update ext.props 
			}
		}
		
		// update syntax ext.props
		synUri	:= `etc/syntax/ext.props`
		synFile := Env.cur.findFile(synUri, false)?.normalize
		if (synFile == null)
			log.warn("Could not find file: ${synUri}")

		else {
			synProps := synFile.readProps
			if (!synProps.containsKey("fandoc") || !synProps.containsKey("fdoc")) {
				synStr := synFile.readAllStr + "\n// fandoc rules\n"

				if (!synProps.containsKey("fandoc"))
					synStr += "fandoc=fandoc\n"

				if (!synProps.containsKey("fdoc"))
					synStr += "fdoc=fandoc\n"

				synFile.out.writeChars(synStr).close
				log.info("Updated syntax mapping file: ${etcFile}")
			}
		}
	}
	
	private static Void addRecursive(Uri[] resDirs, File dir) {
		if (!dir.isDir) throw Err("`${dir.normalize}` is not a directory")
		dir.walk { if (it.isDir) resDirs.add(it.uri) }
	}
}
