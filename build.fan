using build
using compiler
using fanr

class Build : BuildPod {

	new make() {
		podName = "afEggbox"
		summary = "A website for uploading, viewing, and downloading Fantom pods. Host your very own Pod Repository!"
		version = Version("0.1.4")

		meta = [
			"pod.dis"		: "Eggbox",
			"afIoc.module"	: "afEggbox::CoreModule",
			"repo.tags"		: "app",
			"repo.public"	: "true"
		]

		depends = [
			"sys          1.0.77 - 1.0",
			"concurrent   1.0.77 - 1.0",
			"fanr         1.0.77 - 1.0",
			"fandoc       1.0.77 - 1.0",
			"email        1.0.77 - 1.0",
			"gfx          1.0.77 - 1.0",

			// ---- Core ------------------------
			"afBeanUtils  1.0.10 - 1.0",
			"afConcurrent 1.0.26 - 1.0",
			"afIoc        3.0.8  - 3.0",
			"afIocConfig  1.1.0  - 1.1",
			"afIocEnv     1.1.0  - 1.1",

			// ---- Database --------------------
			"afBson       2.0.2  - 2.0",
			"afMongo      2.1.0  - 2.1",
			"afMorphia    2.0.2  - 2.0",
			"afMorphiaIoc 1.0.2  - 1.0",

			// ---- Web -------------------------
			"afBedSheet   1.5.16 - 1.5",
			"afEfanXtra   2.0.4  - 2.0",
			"afPillow     1.2.2  - 1.2",
			"afDuvet      1.1.10 - 1.1",
			"afSlim       1.3.2  - 1.3",
			"afFormBean   1.2.6  - 1.2",
			"afColdFeet   1.4.0  - 1.4",
			"afSitemap    1.1.2  - 1.1",
			"afGoogleAnalytics 0.1.8 - 0.1",
			"afAtom       1.0.2  - 1.0",

			// ---- Other -----------------------
			"afButter     1.2.14 - 1.2",
			"afPegger     1.1.4  - 1.1",
			"syntax       1.0.77 - 1.0",
			"util         1.0.77 - 1.0",
			"web          1.0.77 - 1.0",
			"xml          1.0.77 - 1.0",

			// ---- Test ------------------------
			"afBounce     1.1.12 - 1.1",
			"afFancordion 1.1.4  - 1.1",
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
}
