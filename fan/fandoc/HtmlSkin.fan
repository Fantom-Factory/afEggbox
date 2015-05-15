
mixin HtmlSkin {
	
	abstract OutStream out
	
	virtual This h(Int level, Str? id)	{ w("<h${level}").attr("id", id).w(">") 						}
	virtual This hEnd(Int level)		{ w("</h${level}>")												}

	virtual This p(Str? admonition)		{ w("<p").attr("class", admonition).w(">")						}
	virtual This pEnd()					{ w("</p>") 													}

	virtual This i()					{ w("<i>")			 											}
	virtual This iEnd()					{ w("</i>")			 											}
	
	virtual This b()					{ w("<b>")			 											}
	virtual This bEnd()					{ w("</b>")			 											}

	virtual This a(Uri href)			{ w("<a").attr("href", href).w(">")								}
	virtual This aEnd()					{ w("</a>")														}

	virtual This code() 				{ w("<code>") 													}
	virtual This codeEnd()				{ w("</code>") 													}

	virtual This img(Uri src, Str? alt)	{ w("<img").attr("src", src).attr("alt", alt).w(">")			}

	virtual This pre() 					{ w("<pre>") 													}
	virtual This preEnd()				{ w("</pre>") 													}

	virtual This blockQuote() 			{ w("<blockquote>") 											}
	virtual This blockQuoteEnd()		{ w("</blockquote>") 											}
	
	virtual This ol(Str style)			{ w("<ol").attr("style", "list-style-type: ${style}").w(">")	}
	virtual This olEnd()				{ w("</ol>")		 											}

	virtual This ul()					{ w("<ul>")														}
	virtual This ulEnd()				{ w("</ul>")		 											}

	virtual This li()					{ w("<li>")														}
	virtual This liEnd()				{ w("</li>")		 											}

	
	virtual This w(Str str) {
		out.print(str)
		return this
	}

	virtual This escape(Str text) {
		out.writeXml(text)
		return this
	}
	
	virtual This attr(Str key, Obj? val) {
		if (val == null) return this
		val = val is Uri ? val->encode : val.toStr
		out.writeChar(' ').print(key).print("=\"")
		out.writeXml(val, OutStream.xmlEscQuotes)
		out.writeChar('"')
		return this
	}
}

class MyHtmlSkin : HtmlSkin {
	override OutStream out
	StrBuf buf
	new make() {
		buf = StrBuf()
		out = buf.out
	}
	override Str toStr() {
		buf.toStr
	}
}