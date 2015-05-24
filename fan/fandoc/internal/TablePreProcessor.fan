using afIoc

internal const class TablePreProcessor : PreTextProcessor {
	
	@Inject private const Fandoc fandoc
			private const TableParser tableParser	:= TableParser()
	
	new make(|This|in) { in(this) }
	
	override Void process(Uri cmd, Str preText, HtmlSkin skin) {
		
		table := tableParser.parseTable(preText.splitLines)
		
		echo(table)
		skin.table
		if (!table.first.isEmpty) {
			skin.thead
			skin.tr
			table.first.each { 
				skin.th
				// FIXME: need linkresolver
				fandoc.writeStrToHtml(it, LinkResolverCtx(), skin)
				skin.thEnd
			}
			skin.trEnd			
			skin.theadEnd
		}
		
		skin.tbody
		table.eachRange(1..-1) |row| {
			skin.tr
			row.each { 
				skin.td
				// FIXME: need linkresolver
				fandoc.writeStrToHtml(it, LinkResolverCtx(), skin)
				skin.tdEnd }
			skin.trEnd			
		}
		skin.tbodyEnd
		skin.tableEnd
	}
}
