using syntax
using web

const class SyntaxWriter {
	
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
				html := (Str?) SyntaxType#.field("html").get(type)
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
