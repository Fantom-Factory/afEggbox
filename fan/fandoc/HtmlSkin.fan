using web

mixin HtmlSkin {
	
	abstract WebOutStream	out
	abstract Str 			toHtml()
	
	virtual This fandoc()				{ w("<div").attr("class", "fandoc").w(">") 						}
	virtual This fandocEnd()			{ w("</div>")							 						}

	virtual This h(Int level, Str? id)	{ w("<h${level}").attr("id", id).w(">") 						}
	virtual This hEnd(Int level)		{ w("</h${level}>")												}

	virtual This p(Str? admonition)		{ w("<p").attr("class", admonition).w(">")						}
	virtual This pEnd()					{ w("</p>") 													}

	virtual This i()					{ w("<i>")			 											}
	virtual This iEnd()					{ w("</i>")			 											}
	
	virtual This b()					{ w("<b>")			 											}
	virtual This bEnd()					{ w("</b>")			 											}

	virtual This a(Uri href, Bool broken){ w("<a").attr("href", broken ? `/ERROR` : href).w(">")		}
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

	virtual This table()				{ w("<table>")													}
	virtual This tableEnd()				{ w("</table>")													}
	virtual This thead()				{ w("<thead>")													}
	virtual This theadEnd()				{ w("</thead>")													}
	virtual This tbody()				{ w("<tbody>")													}
	virtual This tbodyEnd()				{ w("</tbody>")													}
	virtual This tr()					{ w("<tr>")														}
	virtual This trEnd()				{ w("</tr>")													}
	virtual This th()					{ w("<th>")														}
	virtual This thEnd()				{ w("</th>")													}
	virtual This td()					{ w("<td>")														}
	virtual This tdEnd()				{ w("</td>")													}
	
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

internal class DefaultHtmlSkin : HtmlSkin {
	override WebOutStream out
	StrBuf	buf

	new make() {
		buf = StrBuf()
		out = WebOutStream(buf.out)
	}
	
	override Str toHtml() {
		buf.toStr
	}
	override Str toStr() {
		buf.toStr
	}
}

internal class BootstrapHtmlSkin : DefaultHtmlSkin {
	
	override This a(Uri href, Bool broken) {
		if (broken)
			w("<a").attr("class", "brokenLink").attr("rel", "nofollow").attr("href", href).w(">")
		else
			w("<a").attr("href", href).w(">")
		return this
	}
	
	override This table() { w("<table").attr("class", "table table-condensed table-striped table-hover").w(">") }

}