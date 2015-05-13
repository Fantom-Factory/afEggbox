using afIoc
using fandoc
using afBedSheet::FileHandler

class HtmlWriter : DocWriter {
	static const Str[] voidTags := "area, base, br, col, embed, hr, img, input, keygen, link, menuitem, meta, param, source, track, wbr".split(',')
	
//	@Inject LinkResolver 	linkResolvers
//	@Inject PreProcessors	preProcessors
	
	private OutStream? 	out
	private Bool		pre
	private Bool		readable
	private DocElem?	readableElem

	new make(|This| in) { 
		in(this) 
	}
	
	Str toHtml(Str fandoc) {
		doc := FandocParser().parseStr(fandoc)
		buf := StrBuf()
		out = buf.out
		doc.writeChildren(this)
		return buf.toStr
	}
	
	override Void docStart(Doc doc) { }
	override Void docEnd(Doc doc) { }
	
	override Void elemStart(DocElem elem) {
		if (elem.isBlock) out.writeChar('\n')

		// for <p> inside <li>
		if (elem.isBlock && readableElem != null) {
			out.print("</span>")
			readableElem = null
		}
		
		out.writeChar('<').print(elem.htmlName)
		if (elem.anchorId != null) 
			attr("id", elem.anchorId)
		
		readable = false
		
		switch (elem.id) {
			case DocNodeId.heading:
				heading := elem as Heading
				readable = heading.level > 1
			
				// auto generate an ID if one isn't set explicitly
				if (heading.anchorId == null)
					attr("id", heading.title.fromDisplayName)

			case DocNodeId.image:
				img := elem as Image
				// see `http://localhost:8069/articles/using-mercurial-and-git-in-harmony` for a good use of img-responsive!
				attr("class", "img-responsive")
//				attr("src", img.uri.startsWith("http://") || img.uri.startsWith("https://") || img.uri.startsWith("data:") ? img.uri : fileHandler.fromLocalUrl(img.uri.toUri).clientUrl)
				attr("alt", img.alt)

			case DocNodeId.link:
				link := elem as Link
//				uri  := linkResolvers.resolve(doc, link.uri.toUri)
				uri  := link.uri
				attr("href", uri)
				if (uri.toStr.startsWith("http"))
					attr("class", "externalLink")

			case DocNodeId.orderedList:
				ol := elem as OrderedList
				attr("style", "list-style-type: ${ol.style.htmlType};")
			
			case DocNodeId.listItem:
				readable = true

			case DocNodeId.para:
				para := elem as Para
				if (para.admonition != null) 
					attr("class", para.admonition.lower)
				// can't remember why I wouldn't want the 'blend' class
//				readable = !para.children.any { it.id == DocNodeId.image }
				// anyway, as I have images in-lined in paragraphs (LEAD:) we'll use 'blend' all the time
				readable = true

			case DocNodeId.pre:
				attr("class", "hilite")				
		}
		
		end := startTag(elem.htmlName, elem.children.isEmpty)
		out.print(end)
		
		if (readable) {
			out.print("""<span class="blend">""")
			readableElem = elem
		}
		pre = (elem.id == DocNodeId.pre)
	}

	override Void text(DocText docText) {
//		if (pre && docText.str.lower.startsWith("syntax:")) {
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
			safeText(docText.str)
	}

	override Void elemEnd(DocElem elem) {
		if (elem == readableElem) {
			out.print("</span>")
			readableElem = null
		}
		
		end := endTag(elem.htmlName, elem.children.isEmpty)
		out.print(end)

		if (elem.isBlock) out.writeChar('\n')
	}

	private Void attr(Str name, Obj val) {
		out.writeChar(' ').print(name).print("=\"")
		out.writeXml(val.toStr, OutStream.xmlEscQuotes)
		out.writeChar('"')
	}

	private Void safeText(Str s) {
		s.each |Int ch| {
			if (ch == '<') out.print("&lt;")
			else if (ch == '&') out.print("&amp;")
			else out.writeChar(ch)
		}
	}
	
	private Str startTag(Str tag, Bool isEmpty) {
		if (isVoid(tag) && isEmpty)
			return " />"
		if (isVoid(tag) && !isEmpty)
			typeof.pod.log.warn("Void tag '${tag}' *MUST NOT* have content!") 
		return ">"
	}

	private Str endTag(Str tag, Bool isEmpty) {
		if (isVoid(tag) && isEmpty)
			return ""
		return "</${tag.toXml}>"
	}
	
	private Bool isVoid(Str tag) {
		voidTags.contains(tag.lower)
	}
}

