using afIoc
using fandoc
using afBedSheet::FileHandler

internal class HtmlWriter : DocWriter {
	
	@Inject private	LinkResolvers 		linkResolvers
	@Inject private PreTextProcessors	preProcessors	
			private HtmlSkin?			skin
			private LinkResolverCtx?	ctx
			private Bool				inPreText

	new make(LinkResolverCtx? ctx, HtmlSkin? htmlSkin, |This| in) {
		this.ctx  = ctx
		this.skin = htmlSkin ?:  DefaultHtmlSkin()
		in(this)
	}
	
	override Void docStart(fandoc::Doc doc) { }
	override Void docEnd(fandoc::Doc doc) { }
	
	override Void elemStart(DocElem elem) {
		switch (elem.id) {
			case DocNodeId.doc:
				//doc := elem as Doc
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
				// pre := elem as Pre
				// skin.pre
				null?.toStr

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
				href := linkResolvers.resolve(link.uri.toUri, ctx)
				skin.a(href)

			case DocNodeId.image:
				img := elem as Image
				src := linkResolvers.resolve(img.uri.toUri, ctx)
				skin.img(src, img.alt)
		}
		
		inPreText = (elem.id == DocNodeId.pre)
	}

	override Void text(DocText docText) {
		if (inPreText) {
			idx		:= docText.str.index("\n") ?: -1
			cmdTxt	:= docText.str[0..idx].trim
			cmd 	:= (Uri?) null
			try { cmd = cmdTxt.toUri } catch { }
			if (cmd != null && preProcessors.canProcess(cmd)) {
				preText := docText.str[idx..-1]
				preProcessors.process(cmd, preText, skin)
				return
			}
			
			skin.pre.escape(docText.str).preEnd
			return
		}
		
		skin.escape(docText.str)
	}

	override Void elemEnd(DocElem elem) {
		switch (elem.id) {
			case DocNodeId.doc:
				//doc := elem as Doc
				// ??? <body> + meta

			case DocNodeId.heading:
				heading := elem as Heading
				skin.hEnd(heading.level)
			
			case DocNodeId.para:
				skin.pEnd

			case DocNodeId.pre:
				// skin.preEnd
				null?.toStr

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
				null?.toStr
		}
	}
	
	Str toHtml() {
		skin.toHtml
	}
}

