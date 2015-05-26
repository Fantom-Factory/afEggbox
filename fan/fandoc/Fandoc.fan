using afIoc
using fandoc
using web

// TODO: make Fandoc lib not IoC
const class Fandoc {
	
	@Inject	private const |LinkResolverCtx?, HtmlSkin?->HtmlWriter| htmlWriter
	
	private new make(|This|in) { in(this) }
	
	Doc parseStr(FandocParser parser, Str fandoc) {
		parser.silent = true
		doc := parser.parse("str", fandoc.in, true)
		return doc
	}
	
	Str writeStrToHtml(Str fandoc, LinkResolverCtx ctx, HtmlSkin? skin := null) {
		parser	:= FandocParser()
		doc 	:= parseStr(parser, fandoc)

		if (parser.errs.size > 0) {
			buf := StrBuf()
			out := WebOutStream(buf.out)
			out.pre
			out.w("Fandoc ERRORS:\n")
			parser.errs.each |err| {
				out.w("Line ${err.line} : ${err.msg}")
			}
			out.w("\n\n")
			out.writeXml(fandoc)
			out.preEnd
			return buf.toStr
		}

		return writeDocToHtml(doc, ctx, skin)
	}

	Str writeDocToHtml(Doc doc, LinkResolverCtx ctx, HtmlSkin? skin := null) {
		ctx.withDoc(doc) |ctx2->Str| {
			skin = skin ?: BootstrapHtmlSkin()
			skin.fandoc
			htmlWriter := htmlWriter(ctx2, skin ?: BootstrapHtmlSkin())
			doc.writeChildren(htmlWriter)
			skin.fandocEnd
			return htmlWriter.toHtml
		}
	}
}
