using afIoc
using syntax

class SyntaxPreProcessor : PreTextProcessor {
	
	@Inject	private SyntaxWriter	syntaxWriter
	
	new make(|This|in) { in(this) }
	
	override Void process(Uri cmd, Str preText, HtmlSkin skin) {
		ext := cmd.pathStr.trim
		if (ext == "fantom")
			ext = "fan"

		// trim new lines, but not spavces
		while (preText.startsWith("\n"))
			preText = preText[1..-1]
		while (preText.endsWith("\n"))
			preText = preText[0..-2]

		syntax := syntaxWriter.writeSyntax(preText, ext)
		skin.w(syntax)
	}
}
