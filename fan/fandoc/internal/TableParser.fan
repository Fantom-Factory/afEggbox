
internal const class TableParser {
	
	Str[][] parseTable(Str[] lines) {
		ctrl := (Str) (lines.find { it.trim.startsWith("-") } ?: throw ParseErr("Could not find table syntax in:\n" + lines.join("\n")))
		
		// find the ranges of the ---'s
		colRanges := Range[,]
		last := 0
		while (last < ctrl.size && ctrl.index("-", last) != null) {
			start := ctrl.index("-", last)
			end := start
			while (end < ctrl.size && ctrl[end] == '-') end++
			dashes := ctrl[start..<end]
			if (!dashes.trim.isEmpty)
				colRanges.add(start..<end)
			last = end
		}
		
		// extend the ranges to the start of the next - dash
		colRanges = colRanges.map |col, i -> Range| {
			next := colRanges.getSafe(i+1)
			end  := next == null ? Int.maxVal : next.start - 1
			return col.start..<end
		}

		inHeader := true
		headers  := Str[,]
		rows	 := Str[][,]
		lines.each |line| {
			if (line.trim.isEmpty)
				return

			if (inHeader) {
				if (line.trim.startsWith("-")) {
					inHeader = false
					return
				}
				colRanges.each |col, i| {
					header := getTableData(line, col)
					if (header != null)
						if (i < headers.size)
							headers[i] = "${headers[i]} ${header}".trim
						else
							headers.add(header)
				}
			} else {
				row := Str[,]
				colRanges.each |col| {
					data := getTableData(line, col)
					if (data != null)
						row.add(data)
				}
				if (!row.isEmpty)
					rows.add(row)
			}
		}

		return rows.insert(0, headers)
	}

	private Str? getTableData(Str line, Range col) {
		data := (Str?) Str.defVal
		if (col.start < line.size)
			if (col.end < line.size)
				data = line.getRange(col).trim
			else
				data = line.getRange(col.start..-1).trim
		
		if (data.isEmpty)
			return data

		// special case for fancy tables - needed for the last column where we grab all we can
		if (!data.isEmpty && (data[-1] == '|' || data[-1] == '+'))
			data = data[0..<-1].trim
		
		return data.chars.all { it == '-' || it == '=' || it.isSpace } ? null : data
	}
}
