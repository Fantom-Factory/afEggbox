using afIoc
using fandoc
using web

// TODO: make Fandoc lib not IoC
const class Fandoc {
	
	@Inject	private const |LinkResolverCtx?, HtmlSkin?->HtmlWriter| htmlWriter
	
	private new make(|This|in) { in(this) }
	
	Str writeStrToHtml(Str fandoc, LinkResolverCtx? ctx := null, HtmlSkin? skin := null) {
		parser := FandocParser()
		parser.silent = true
		doc := parser.parse("str", fandoc.in, true)

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

	Str writeDocToHtml(Doc doc, LinkResolverCtx? ctx := null, HtmlSkin? skin := null) {
		(ctx ?: LinkResolverCtx()).withDoc(doc) |ctx2->Str| {
			htmlWriter := htmlWriter(ctx2, skin)
			doc.writeChildren(htmlWriter)
			return htmlWriter.toHtml
		}
	}
}
