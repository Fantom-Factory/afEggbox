using afIoc
using fandoc

// TODO: make Fandoc lib not IoC
const class Fandoc {
	
	@Inject	private const |HtmlSkin?->HtmlWriter| htmlWriter
	
	private new make(|This|in) { in(this) }
	
	Str writeStrToHtml(Str fandoc, HtmlSkin? skin := null) {
		doc := FandocParser().parseStr(fandoc)
		return writeDocToHtml(doc, skin)
	}

	Str writeDocToHtml(fandoc::Doc doc, HtmlSkin? skin := null) {
		htmlWriter := htmlWriter(skin)
		doc.writeChildren(htmlWriter)
		return htmlWriter.toHtml
	}
}
