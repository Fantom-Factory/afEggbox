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
	
	** Need to wait until *after* layout has rendered to find the HTML tag.
//	@AfterRender
//	Void afterRender(StrBuf buf) {
//		ogasset1	:= fileHandler.fromLocalUrl(`/images/pods/${data.podName}.ogimage.png`, false)
//		ogasset2	:= ogasset1 ?: fileHandler.fromLocalUrl(`/images/AlienFactory-avatar.png`)
//		ogimage		:= bedServer.toAbsoluteUrl(ogasset2.clientUrl)
//		htmlIndex	:= buf.toStr.index("<html ") + "<html ".size
//		absPageUrl	:= bedServer.toAbsoluteUrl(data.clientUrl)
//
//		// ---- Open Graph Meta ---- Mandatory
//		buf.insert(htmlIndex, "prefix=\"og: http://ogp.me/ns#\" ")
//		injector.injectMeta.withProperty("og:type"	).withContent("website")
//		injector.injectMeta.withProperty("og:title"	).withContent("${data.projectName} ${data.version}")
//		injector.injectMeta.withProperty("og:url"	).withContent(absPageUrl.encode)
//		injector.injectMeta.withProperty("og:image"	).withContent(ogimage.encode)
//		
//		// ---- Open Graph Meta ---- Optional
//		injector.injectMeta.withProperty("og:description"	).withContent(data.summary)
//		injector.injectMeta.withProperty("og:locale"		).withContent("en_GB")
//		injector.injectMeta.withProperty("og:site_name"		).withContent("Fantom-Factory")
//	}

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
