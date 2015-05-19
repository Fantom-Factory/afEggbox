using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using fandoc

@Page { disableRoutes = true }
const mixin PodDocPage : PrPage {

	@Inject			abstract Fandoc			fandoc
	@Inject			abstract RepoPodDocsDao	podDocsDao
	@PageContext	abstract RepoPod		pod
	@PageContext	abstract Uri			fileUri
					abstract Doc			doc

	Str docs() {
		podDoc := podDocsDao.find(pod.name, pod.version)[fileUri]?.readAllStr
		if (podDoc == null)
			throw HttpStatusErr(404, "Pod file `${fileUri}` not found")

		doc = fandoc.parseStr(podDoc)
		return LinkResolverCtx().withPod(pod) |ctx->Str| {
			return this.fandoc.writeDocToHtml(doc, ctx)
		}
	}
	
	Str toc(Heading[] headings) {
		if (headings.isEmpty) return ""
		level := headings.first.level
		buf := StrBuf()
		doToc(headings, buf, level, 0)
		return buf.toStr
	}

	Int doToc(Heading[] headings, StrBuf html, Int level, Int i) {
		if (headings.isEmpty) return i

		html.add("<ul>")
		quit := false
		while (!quit && i < headings.size) {
			h := headings[i]
			if (h.level < level) {
				quit = true
				continue
			}
			if (h.level > level) {
//				html.add("<li>")
				i = doToc(headings, html, h.level, i)
//				html.add("</li>")
				continue
			}

			id := h.anchorId ?: h.title.fromDisplayName
			html.add("<li>")
			html.add("<a href=\"#${id}\">${h.title}</a>")
			html.add("</li>")
			i++
		}
		html.add("</ul>")
		return i
	}
	
//  ** Write out pod-doc table of contents.
//  virtual Void writePodDocToc(DocHeading[] headings)
//  {
//    out.ul
//    headings.each |h|
//    {
//      out.li.a(`#$h.anchorId`).esc(h.title).aEnd
//      if (!h.children.isEmpty) writePodDocToc(h.children)
//      out.liEnd
//    }
//    out.ulEnd
//  }
}
