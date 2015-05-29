using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodSummaryPage : PrPage {
	private static const Unit	bytes	:= Unit("byte")
	private static const Unit[] units 	:= ["petabyte", "terabyte", "gigabyte", "megabyte", "kilobyte", "byte"].map { Unit(it) }

	@Inject			abstract Registry			registry
	@Inject			abstract RepoPodDao			podDao
	@Inject			abstract SyntaxWriter		syntaxWriter
	@PageContext	abstract FandocSummaryUri	fandocUri
	
		// TODO: seo this page!
	
	RepoPod pod() {
		fandocUri.pod
	}

	Str aboutHtml() {
		fandocUri.aboutHtml
	}

	Str editUrl() {
		fandocUri.toClientUrl.plusSlash.plusName("edit").encode
	}

	Bool isPublic() {
		pod.isPublic
	}
	
	Str toFileSize(Int size) {
		units.eachWhile { conv(it, size.toFloat) } ?: "0 bytes"
	}
	
	Str linkToPod(Depend pod) {
		podUrl := FandocUri.fromUri(registry, `fandoc:/${pod.name}`)?.toClientUrl

		if (podUrl == null)
			return """<span class="nowrap" title="${pod.toStr}">${pod.name}</span>"""

		if (podUrl.isAbs)
			return """<a href="${podUrl.encode}" class="nowrap sysPodLink" title="${pod.toStr}">${pod.name}</a>"""

		return """<a href="${podUrl.encode}" class="nowrap" title="${pod.toStr}">${pod.name}</a>"""
	}

	private static Str? conv(Unit unit, Float size) {
		scalar	:= bytes.convertTo(size, unit)
		return (scalar > 1f) ? ((unit.name == "byte") ? "$size.toInt bytes" : scalar.toLocale("#,##0.00") + "&#160;$unit.symbol") : null
	}
}
