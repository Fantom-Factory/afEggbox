using afIoc::Inject
using afEfanXtra
using afPillow
using fandoc
using afDuvet::HtmlInjector

const mixin PodToc : PrComponent {

	abstract FandocUri		fandocUri
	
	@InitRender
	Void initRender(FandocUri fandocUri) {
		this.fandocUri = fandocUri
		injector.injectRequireScript(["jquery":"\$", "bootstrap":"bs"], "\$('body').scrollspy({ target: '#navToc' })")
		injector.injectRequireScript(["jquery":"\$", "bootstrap":"bs"], "\$('.sideMenu').affix({ offset: { top: 70, bottom: function () { return (this.bottom = \$('#fatFooter').outerHeight(true)) } } })")
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
		
		if (fandocUri.pod.hasApi) {
			apiUri := fandocUri.toApiUri
			if (fandocUri is FandocApiUri && (fandocUri as FandocApiUri).typeName == null)
				html.add("<h4 class=\"text-muted\">").add("API").add("</h4>")
			else {
				html.add("<h4>").add("<a href=\"${apiUri.toClientUrl.encode}\">").add("API").add("</a>").add("</h4>")
			}
		}
		
		if (fandocUri.pod.hasDocs) {
			docUri := fandocUri.toDocUri
			contents := docUri.pageContents
	
			contents.each |title, page| { 
				link  := docUri.toDocUri(page)
				if (fandocUri is FandocDocUri && (fandocUri as FandocDocUri).fileUri == link.fileUri) {
					html.add("<h4 class=\"text-muted\">").add(title).add("</h4>")
					html.add("<nav id=\"navToc\" >")
					heads := link.findHeadings
					doToc(page, heads, html, heads.first?.level ?: 0, 0, true)
					html.add("</nav>")
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
			html.add("<ul class=\"list-unstyled nav\">")
		else
			html.add("<ul class=\"list-unstyled\">")
		quit := false
		while (!quit && i < headings.size) {
			h := headings[i]
			if (h.level < level) {
				quit = true
				continue
			}
			if (h.level > level) {
				html.removeRange(-5..-1)
				i = doToc(page, headings, html, h.level, i, false)
				html.add("</li>")
				continue
			}

			id  := h.anchorId ?: Utils.fromDisplayName(h.title)

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
