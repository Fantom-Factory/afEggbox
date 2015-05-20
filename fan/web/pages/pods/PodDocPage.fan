using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using fandoc

@Page { disableRoutes = true }
const mixin PodDocPage : PrPage {

	@Inject			abstract Fandoc				fandoc
	@Inject			abstract RepoPodDocsDao		podDocsDao
	@Inject			abstract |RepoPod, Uri?, Str? -> FandocDocUri| docUriFactory
	@Inject			abstract |RepoPod, Str?, Str? -> FandocApiUri| apiUriFactory
	@PageContext	abstract RepoPod			pod
	@PageContext	abstract Uri				fileUri
					abstract RepoPodDocs?		podDocs
					abstract LinkResolverCtx?	linkResolverCtx

	@BeforeRender
	Void beforeRender() {
		podDocs = podDocsDao.find(pod.name, pod.version)
		if (!podDocs.contents.containsKey(fileUri))
			throw HttpStatusErr(404, "Pod file `${fileUri}` not found")
		linkResolverCtx = LinkResolverCtx {
			it.pod = this.pod
		}
	}

	Str docs() {
		docStr	:= podDocs[fileUri]?.readAllStr
		doc 	:= fandoc.parseStr(docStr)
		return this.fandoc.writeDocToHtml(doc, linkResolverCtx)
	}
	
	Str apiUrl() {
		apiUriFactory(pod, null, null).toClientUrl.encode
	}
	
	Str tableOfContents() {
		html	:= StrBuf()
		contents := (Obj[][]) podDocs.pages.map { it.relTo(`/doc`) }.exclude { it == `pod.fandoc`}.sort.map |Uri page->Obj| { [page, page.name[0..<page.name.indexr(".")].toDisplayName] }.insert(0, [`pod.fandoc`, "User Guide"])
		
		contents.each { 
			page  := (Uri) `/doc/` + it[0] 
			title := (Str) it[1]
			link  := (FandocDocUri) docUriFactory(pod, page, null)
			if (link.fileUri == this.fileUri)
				html.add("<h4 class=\"text-muted\">").add(title).add("</h4>")
			else
				html.add("<h4>").add("<a href=\"${link.toClientUrl.encode}\">").add(title).add("</a>").add("</h4>")
			heads := link.findHeadings
			doToc(page, heads, html, heads.first?.level ?: 0, 0)
		}
		
		return html.toStr
	}

	Int doToc(Uri page, Heading[] headings, StrBuf html, Int level, Int i) {
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
				i = doToc(page, headings, html, h.level, i)
//				html.add("</li>")
				continue
			}

			id  := h.anchorId ?: h.title.fromDisplayName

			html.add("<li>")
			if (page == this.fileUri)
				html.add("<a href=\"#${id.toUri.encode}\">${h.title}</a>")
			else {
				link := (FandocDocUri) docUriFactory(pod, page, id)
				html.add("<a href=\"${link.toClientUrl.encode}\">${h.title}</a>")
			}
			html.add("</li>")
			i++
		}
		html.add("</ul>")
		return i
	}
}
