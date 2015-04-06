using build

class Build : BuildPod {

	new make() {
		podName = "afPodRepo"
		summary = "Fantom Pod Repository"
		version = Version("0.0.1")

		meta = [
			"proj.name"		: "Fantom Pod Repository",
			"afIoc.module"	: "afPodRepo::PodRepoModule",
			"internal"		: "true",
			"tags"			: "app",
			"repo.private"	: "true"
		]

		depends = [
			"sys          1.0.67 - 1.0",
			"fanr         1.0.67 - 1.0",
			"fandoc       1.0.67 - 1.0",

			// ---- Core ------------------------
//			"afBeanUtils  1.0.4  - 1.0", 
//			"afConcurrent 1.0.8  - 1.0", 
			"afIoc        2.0.6  - 2.0", 
			"afIocConfig  1.0.16 - 1.0", 
			"afIocEnv     1.0.18 - 1.0", 
			
			// ---- Database --------------------
//			"afBson       1.0.0  - 1.0",
			"afMongo      1.0.0  - 1.0",
			"afMorphia    1.0.2  - 1.0",
			
			// ---- Web -------------------------
			"afBedSheet   1.4.8  - 1.4",
//			"afEfanXtra   1.1.2  - 1.1",
//			"afPillow     1.0.22 - 1.0",

			// ---- Test ------------------------
			"afBounce     1.0.20 - 1.0",
			"afFancordion 1.0.0  - 1.0"
		]

		srcDirs = [`test-spec/`, `test-spec/fanr/`, `fan/`, `fan/web/`, `fan/fanr/`, `fan/core/`, `fan/core/entities/`, `fan/core/database/`]
		resDirs = [,]
	}
}
