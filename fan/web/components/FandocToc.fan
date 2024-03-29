using afIoc::Inject
using afEfanXtra
using afPillow
using fandoc
using afDuvet::HtmlInjector

const mixin FandocToc : PrComponent {

	@Inject	abstract FandocWriter	fandoc
			abstract Uri			fileName
	
	@InitRender
	Void initRender(Uri fileName) {
		this.fileName = fileName
//		injector.injectRequireScript(["jquery":"\$", "bootstrap":"bs"], "\$('body').scrollspy({ target: '#navToc', offset: 71 })")
		injector.injectRequireScript(["jquery":"\$", "bootstrap":"bs"], "\$('.sideMenu').affix({ offset: { top: 70, bottom: function () { return (this.bottom = \$('#fatFooter').outerHeight(true)) } } })")
	}
	
	override Str renderTemplate() {
		html	:= StrBuf()
		html.add("<h3>Contents</h3>")

		fandocFile := fileName.relTo(`/`).toFile
		doc := fandoc.parseStr(FandocParser(), fandocFile.readAllStr)

//		html.add("<h4 class=\"text-muted\">").add(fileName.name.toDisplayName).add("</h4>")
		heads := doc.findHeadings
		doToc(heads, html, heads.first?.level ?: 0, 0, true)
		
		return html.toStr
	}

	Int doToc(Heading[] headings, StrBuf html, Int level, Int i, Bool topLevel) {
		if (headings.isEmpty) return i

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
				html.removeRange(-5..-1)
				i = doToc(headings, html, h.level, i, false)
				html.add("</li>")
				continue
			}

			id  := h.anchorId ?: Utils.fromDisplayName(h.title)

			html.add("<li><a href=\"#${id.toUri.encode}\">${h.title}</a></li>")
			i++
		}
		html.add("</ul>")
		return i
	}
	
	static private Str[] findTextNodes(DocElem elem, Str[] texts) {
		elem.children.each {
			if (it is DocText)
				texts.add(((DocText) it).str)
			if (it is DocElem)
				findTextNodes(it, texts)
		}
		return texts
	}
}
