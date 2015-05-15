using afIoc
using fandoc
using afBedSheet::FileHandler

class HtmlWriter : DocWriter {
	
//	@Inject LinkResolver 	linkResolvers
//	@Inject PreProcessors	preProcessors
	
	private HtmlSkin?	skin
	private Bool		inPreText

	new make(|This| in) { 
		in(this) 
	}
	
	Str toHtml(Str fandoc) {
		doc := FandocParser().parseStr(fandoc)
		skin = MyHtmlSkin()
		doc.writeChildren(this)
		return skin.toStr
	}
	
	override Void docStart(Doc doc) { }
	override Void docEnd(Doc doc) { }
	
	override Void elemStart(DocElem elem) {
		switch (elem.id) {
			case DocNodeId.doc:
				doc := elem as Doc
				// ??? <body> + meta

			case DocNodeId.heading:
				heading := elem as Heading
				// auto generate an ID if one isn't set explicitly
				id := heading.anchorId ?: heading.title.fromDisplayName
				skin.h(heading.level, id)
			
			case DocNodeId.para:
				para := elem as Para
				skin.p(para.admonition)

			case DocNodeId.pre:
				pre := elem as Pre
				skin.pre

			case DocNodeId.blockQuote:
				blockQuote := elem as BlockQuote
				skin.blockQuote

			case DocNodeId.orderedList:
				ol := elem as OrderedList
				skin.ol(ol.style.htmlType)

			case DocNodeId.unorderedList:
				ul := elem as UnorderedList
				skin.ul

			case DocNodeId.listItem:
				li := elem as ListItem
				skin.li

			case DocNodeId.emphasis:
				i := elem as Emphasis
				skin.i

			case DocNodeId.strong:
				b := elem as Strong
				skin.b

			case DocNodeId.code:
				code := elem as Code
				skin.code

			case DocNodeId.link:
				link := elem as Link
				href := link.uri.toUri	// FIXME: resolve img URI
				skin.a(href)

			case DocNodeId.image:
				img := elem as Image
				src := img.uri.toUri	// FIXME: resolve img URI
				skin.img(src, img.alt)
		}
		
		inPreText = (elem.id == DocNodeId.pre)
	}

	override Void text(DocText docText) {
//		if (inPreText && docText.str.lower.startsWith("syntax:")) {
//			lines	:= docText.str.splitLines
//			syntax 	:= lines[0]["syntax:".size..-1].trim.lower
//			lines.removeAt(0)
//			while (!lines.isEmpty && lines[0].trim.isEmpty)
//				lines.removeAt(0)
//			text 	:= lines.join("\n")
//			uri		:= doc.meta[Article.FILE_META_ID].toUri
//			if (highlightSyntax && isValid(syntax)) {
//				html	:= syntaxHilighter.hilight(uri, syntax, text) 
//				out.print(html)
//			} else {
//				safeText(text)
//			}
//		} else
			skin.escape(docText.str)
	}

	override Void elemEnd(DocElem elem) {
		switch (elem.id) {
			case DocNodeId.doc:
				doc := elem as Doc
				// ??? <body> + meta

			case DocNodeId.heading:
				heading := elem as Heading
				skin.hEnd(heading.level)
			
			case DocNodeId.para:
				skin.pEnd

			case DocNodeId.pre:
				skin.preEnd

			case DocNodeId.blockQuote:
				skin.blockQuoteEnd

			case DocNodeId.orderedList:
				skin.olEnd

			case DocNodeId.unorderedList:
				skin.ulEnd

			case DocNodeId.listItem:
				skin.liEnd

			case DocNodeId.emphasis:
				skin.iEnd

			case DocNodeId.strong:
				skin.bEnd

			case DocNodeId.code:
				skin.codeEnd

			case DocNodeId.link:
				skin.aEnd

			case DocNodeId.image:
				// skin.imgEnd
		}
	}
}

