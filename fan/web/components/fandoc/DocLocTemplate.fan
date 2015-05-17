using afIoc
using afEfanXtra
 
const mixin DocLocTemplate : EfanComponent {
	
	abstract LinkResolverCtx	ctx
	abstract DocLoc				ref

	@InitRender
	Void init(LinkResolverCtx ctx, DocLoc ref) {
		this.ctx	= ctx
		this.ref	= ref
	}
	
	override Str renderTemplate() {
		""
	}
	
//  ** Write source code link as <p> if source is available.
//  virtual Void writeSrcLink(DocLoc loc, Str dis := "Source")
//  {
//    link := toSrcLink(loc, dis)
//    if (link == null) return
//    out.p("class='src'")
//    writeLink(link)
//    out.pEnd
//  }
//  ** Map filename/line number to a source file link
//  DocLink? toSrcLink(DocLoc loc, Str dis)
//  {
//    src := type.pod.src(loc.file, false)
//    if (src == null) return null
//    frag := loc.line > 20 ? "line${loc.line}" : null
//    return DocLink(doc, src, dis, frag)
//  }

}
