using afEfanXtra
using afIoc
using afIocEnv
using afDuvet

const mixin FatFooter : PrComponent { 

	@Inject abstract PodRepoConfig repoConfig
	
	@InitRender
	Void initRender() {
	}
	
}