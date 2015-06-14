using afIoc::Inject
using afEfanXtra
using afPillow
using fandoc

const mixin HelpToc : PrComponent {

	@Inject	abstract FandocWriter	fandoc
			abstract Uri			fileName
	
	@InitRender
	Void initRender(Uri fileName) {
		this.fileName = fileName
	}
	
	override Str renderTemplate() {
		html	:= StrBuf()
		html.add("<h3>Get Started</h3>")

		fandocFile := `etc/web-pages/help/${fileName}`.toFile
		doc := fandoc.parseStr(FandocParser(), fandocFile.readAllStr)

		contents := Type:Str[:] { ordered = true }
			.add(HelpPublishPage#,	"Publishing Pods")
			.add(HelpFandocPage#, 	"Writing Documentation")
			.add(HelpFanrPage#, 	"Using fanr")

		contents.each |title, pageType| { 
			link  := pages[pageType]
			// TODO: tidy this tenuous link!
			if (fileName.toStr[0..<-7] == pageType.name[0..<-4]) {
				html.add("<h4 class=\"text-muted\">").add(title).add("</h4>")
				heads := doc.findHeadings
				doToc(heads, html, heads.first?.level ?: 0, 0, true)
			} else
				html.add("<h4>").add("<a href=\"${link.pageUrl.encode}\">").add(title).add("</a>").add("</h4>")
			
		}
		
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
				i = doToc(headings, html, h.level, i, false)
				continue
			}

			id  := h.anchorId ?: h.title.fromDisplayName

			html.add("<li><a href=\"#${id.toUri.encode}\">${h.title}</a></li>")
			i++
		}
		html.add("</ul>")
		return i
	}
}
