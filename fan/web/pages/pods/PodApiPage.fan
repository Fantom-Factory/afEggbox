using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodApiPage : PrPage {

	@Inject			abstract RepoPodApiDao		podApiDao
	@Inject			abstract RepoPodSrcDao		podSrcDao
	@Inject			abstract Fandoc				fandoc
	@PageContext	abstract RepoPod			pod
	@PageContext	abstract Uri				fileUri
					abstract DocType			type
					abstract LinkResolverCtx	ctx
					abstract Str?				typeSrcUrl
					abstract Str?				slotSrcUrl

	@BeforeRender
	Void beforeRender() {
//		apiDoc := podApiDao.get(pod._id, false)?.get(fileUri)
//		if (apiDoc == null)
//			throw HttpStatusErr(404, "Pod API for `${fileUri}` not found")
//		
//		this.type	= ApiDocParser(pod.name, apiDoc.in).parseType(true)
		this.ctx	= LinkResolverCtx() { 
			it.pod 	= this.pod
			it.type	= this.type.name
		} 
	}
	
	Str writeFandoc(DocFandoc doc) {
		fandoc.writeStrToHtml(doc.text, ctx)
	}
	
	Bool typeHasSrc() {
		uri := `fandoc:/${pod.name}/src/${type.name}`.plusQuery(["v":pod.version.toStr])
		typeSrcUrl = linkResolvers.resolve(uri)?.encode
		return typeSrcUrl != null
	}

	Bool slotHasSrc(DocSlot slot) {
		uri := `fandoc:/${pod.name}/src/${type.name}/${slot.name}#line${slot.loc.line}`.plusQuery(["v":pod.version.toStr])
		slotSrcUrl = linkResolvers.resolve(uri)?.encode
		return slotSrcUrl != null
	}

}
