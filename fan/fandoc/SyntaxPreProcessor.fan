using syntax

class SyntaxPreProcessor : PreTextProcessor {
	
	override Void process(Uri cmd, Str preText, HtmlSkin skin) {
		ext := cmd.pathStr.trim
		if (ext == "fantom")
			ext = "fan"

		// trim new lines, but not spavces
		while (preText.startsWith("\n"))
			preText = preText[1..-1]
		while (preText.endsWith("\n"))
			preText = preText[0..-2]

		skin.out.div("class=\"syntax\"")
		rules	:= SyntaxRules.loadForExt(ext)
		synDoc	:= SyntaxDoc.parse(rules, preText.in)
		HtmlSyntaxWriter(skin.out).writeLines(synDoc)
		skin.out.divEnd
	}
}
