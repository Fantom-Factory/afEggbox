using afIoc
using fandoc

// TODO: make Fandoc lib not IoC
const class Fandoc {
	
	@Inject	private const |LinkResolverCtx?, HtmlSkin?->HtmlWriter| htmlWriter
	
	private new make(|This|in) { in(this) }
	
	Str writeStrToHtml(Str fandoc, LinkResolverCtx? ctx := null, HtmlSkin? skin := null) {
		doc := FandocParser().parseStr(fandoc)
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
