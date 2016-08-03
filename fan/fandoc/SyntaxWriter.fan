using syntax
using web

const class SyntaxWriter {
	
	private static const SyntaxType:Str? htmlTags := [
		SyntaxType.text		: null,
		SyntaxType.bracket	: "b",
		SyntaxType.keyword	: "i",
		SyntaxType.literal	: "em",
		SyntaxType.comment	: "s",	// don't use 'q' as wot 'SyntaxType' does as firefox, when CTRL+C, AWAYS adds quotes around it! 
	]

	Str writeSyntax(Str text, Str extension, Bool renderLineIds) {
		ext	:= extension.lower
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
			writeLines(out, synDoc, renderLineIds)
		}
		
		out.divEnd
		return buf.toStr
	}
	
	Void writeLines(WebOutStream out, SyntaxDoc doc, Bool renderLineIds) {
		out.pre
		doc.eachLine |line| { 
			if (renderLineIds) out.span("id=\"line${line.num}\"")
			line.eachSegment |type, text| {
				html := htmlTags[type]
				if (html != null)
					out.writeChar('<').print(html).writeChar('>')
				out.writeXml(text)
				if (html != null)
					out.writeChars("</").print(html).writeChar('>')
			}
			if (renderLineIds) out.spanEnd
			out.writeChar('\n')		
		}
		out.preEnd
	}

}
