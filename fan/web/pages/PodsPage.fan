using afIoc
using afEfanXtra

const mixin PodsPage : PrPage {

	@InitRender
	Void initRender() {
	}

	RepoPod[] allPods() {
		[,]
	}
	
	Str downloads(Obj o) {
		""
	}
}
