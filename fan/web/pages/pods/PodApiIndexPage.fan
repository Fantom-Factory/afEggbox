using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodApiIndexPage : PrPage {

	@Inject			abstract RepoPodApiDao		podApiDao
	@Inject			abstract Fandoc				fandoc
	@PageContext	abstract RepoPod			pod
					abstract LinkResolverCtx	ctx
					abstract RepoPodApi?		podApi

	@BeforeRender
	Void beforeRender() {
		podApi = podApiDao.get(pod._id, false)
		if (podApi == null)
			throw HttpStatusErr(404, "API for pod ${pod.name} not found")
		
		this.ctx = LinkResolverCtx() { 
			it.pod = this.pod
		} 
	}
	
	Str writeFandoc(DocFandoc doc) {
		fandoc.writeStrToHtml(doc.text, ctx)
	}
}
