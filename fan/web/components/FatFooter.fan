using afEfanXtra
using afIoc
using afIocEnv
using afDuvet

const mixin FatFooter : PrComponent { 

	@Inject abstract EggboxConfig eggboxConfig
	
	@InitRender
	Void initRender() {
		if (eggboxConfig.contactEnabled)
			injector.injectRequireModule("unscramble", null, ["contactUs"])
	}
	
}