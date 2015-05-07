using afIoc
using afEfanXtra

const mixin PodsPage : PrPage {

	@Inject abstract RepoPodDao		podDao
			abstract RepoPod[]		allPods

	@InitRender
	Void initRender() {
		allPods = podDao.findAll
		injector.injectRequireModule("fileInput")
	}
	
	Str downloads(Obj o) {
		""
	}
}
