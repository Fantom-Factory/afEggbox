using afIoc
using syntax

internal const class SyntaxPreProcessor : PreTextProcessor {
	
	@Inject	private const SyntaxWriter	syntaxWriter
	
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

		syntax := syntaxWriter.writeSyntax(preText, ext, false)
		skin.w(syntax)
	}
}
