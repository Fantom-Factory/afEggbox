using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using fandoc

@Page { disableRoutes = true }
const mixin PodDocPage : PrPage {

//	@Inject			abstract Fandoc				fandoc
//	@Inject			abstract RepoPodDocsDao		podDocsDao
	@Inject			abstract |RepoPod, Uri?, Str? -> FandocDocUri| docUriFactory
	@Inject			abstract |RepoPod, Str?, Str? -> FandocApiUri| apiUriFactory
	@PageContext	abstract FandocDocUri		fandocUri
//	@PageContext	abstract Uri				fileUri
//					abstract RepoPodDocs?		podDocs
//					abstract LinkResolverCtx?	linkResolverCtx

	RepoPod pod() {
		fandocUri.pod
	}

	Str docHtml() {
		fandocUri.docHtml
	}
	
	Str apiUrl() {
		apiUriFactory(pod, null, null).toClientUrl.encode
	}
	
	Str tableOfContents() {
		html	:= StrBuf()
		contents := fandocUri.pageContents

		contents.each |title, page| { 
			link  := (FandocDocUri) docUriFactory(pod, page, null)
			if (link.fileUri == fandocUri.fileUri)
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
			if (page == fandocUri.fileUri)
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
