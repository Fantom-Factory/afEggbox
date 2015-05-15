using build

class Build : BuildPod {

	new make() {
		podName = "afPodRepo"
		summary = "Fantom Pod Repository"
		version = Version("0.0.1")

		meta = [
			"proj.name"		: "Fantom Pod Repository",
			"afIoc.module"	: "afPodRepo::AppModule",
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

		srcDirs = [`test-spec/`, `test-spec/web/`, `test-spec/web/login/`, `test-spec/utils/`, `test-spec/fanr/`, `fan/`, `fan/web/`, `fan/web/util/`, `fan/web/services/`, `fan/web/pages/`, `fan/web/pages/pods/`, `fan/web/pages/my/`, `fan/web/components/`, `fan/fanr/`, `fan/fandoc/`, `fan/core/`, `fan/core/entities/`, `fan/core/database/`, `fan/bedframe/`]
		resDirs = [`res/`]
	}
}
