using afIoc::Inject
using afEfanXtra
using afPillow
using fandoc

const mixin PodToc : EfanComponent {

	@Inject	abstract Pages	 	pages
			abstract FandocUri	fandocUri
	
	@InitRender
	Void initRender(FandocUri fandocUri) {
		this.fandocUri = fandocUri
	}
	
	Str podsUrl() {
		pages[PodsPage#].pageUrl.encode
	}

	override Str renderTemplate() {
		html	:= StrBuf()
		html.add("<h3>Contents</h3>")
		
		if (fandocUri is FandocSummaryUri)
			html.add("<h4 class=\"text-muted\">").add("Summary").add("</h4>")
		else {
			summaryUri := fandocUri.toSummaryUri
			html.add("<h4>").add("<a href=\"${summaryUri.toClientUrl.encode}\">").add("Summary").add("</a>").add("</h4>")
		}
		
		apiUri := fandocUri.toApiUri
		if (apiUri.hasApi)
			if (fandocUri is FandocApiUri && (fandocUri as FandocApiUri).typeName == null)
				html.add("<h4 class=\"text-muted\">").add("API").add("</h4>")
			else {
				html.add("<h4>").add("<a href=\"${apiUri.toClientUrl.encode}\">").add("API").add("</a>").add("</h4>")
			}
		
		docUri := fandocUri.toDocUri
		if (docUri.hasDoc) {
			contents := docUri.pageContents
	
			contents.each |title, page| { 
				link  := docUri.toDocUri(page)
				if (fandocUri is FandocDocUri && (fandocUri as FandocDocUri).fileUri == link.fileUri) {
					html.add("<h4 class=\"text-muted\">").add(title).add("</h4>")
					heads := link.findHeadings
					doToc(page, heads, html, heads.first?.level ?: 0, 0, true)
				} else
					html.add("<h4>").add("<a href=\"${link.toClientUrl.encode}\">").add(title).add("</a>").add("</h4>")
				
			}
		}
		
		return html.toStr
	}

	Int doToc(Uri page, Heading[] headings, StrBuf html, Int level, Int i, Bool topLevel) {
		if (headings.isEmpty) return i

		fandocUri := (FandocDocUri) fandocUri

		if (topLevel)
			html.add("<ul class=\"list-unstyled\">")
		else
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
				i = doToc(page, headings, html, h.level, i, false)
//				html.add("</li>")
				continue
			}

			id  := h.anchorId ?: h.title.fromDisplayName

			html.add("<li>")
			if (page == fandocUri.fileUri)
				html.add("<a href=\"#${id.toUri.encode}\">${h.title}</a>")
			else {
				link := fandocUri.toDocUri(page, id)
				html.add("<a href=\"${link.toClientUrl.encode}\">${h.title}</a>")
			}
			html.add("</li>")
			i++
		}
		html.add("</ul>")
		return i
	}
}