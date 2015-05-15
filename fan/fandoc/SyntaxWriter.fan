using syntax
using web

const class SyntaxWriter {
	
	Str writeSyntax(Str text, Str ext) {		
		buf := StrBuf()
		out := WebOutStream(buf.out)
		out.div("class=\"syntax ${ext}\"")
		
		rules := SyntaxRules.loadForExt(ext)
		if (rules == null) {
			typeof.pod.log.warn("Could not find syntax file for '${ext}'")
			out.pre.writeXml(text).preEnd
		} else {
			
			parserType	:= Type.find("syntax::SyntaxParser")
			parser		:= parserType.method("make").call(rules)
			parserType.field("tabsToSpaces").set(parser, 4)
			synDoc := parserType.method("parse").callOn(parser, [text.in])
			HtmlSyntaxWriter(out).writeLines(synDoc)
		}
		
		out.divEnd
		return buf.toStr
	}
}
