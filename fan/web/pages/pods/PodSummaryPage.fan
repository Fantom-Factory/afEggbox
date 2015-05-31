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
	@Inject			abstract BedSheetServer		bedServer
	@PageContext	abstract FandocSummaryUri	fandocUri
	
	** Need to wait until *after* layout has rendered to find the HTML tag.
	@AfterRender
	Void afterRender(StrBuf buf) {
		pod			:= fandocUri.pod
		ogasset		:= fandocUri.toDocUri(`/doc/ogimage.png`)
		ogimage		:= ogasset.exists ? ogasset.toAsset.clientUrl : fileHandler.fromLocalUrl(`/images/ogimage.png`).clientUrl
		htmlIndex	:= buf.toStr.index("<html ") + "<html ".size
		absPageUrl	:= bedServer.toAbsoluteUrl(fandocUri.toClientUrl)

		// ---- Open Graph Meta ---- Mandatory
		buf.insert(htmlIndex, "prefix=\"og: http://ogp.me/ns#\" ")
		injector.injectMeta.withProperty("og:type"	).withContent("website")
		injector.injectMeta.withProperty("og:title"	).withContent("${pod.projectName} ${pod.version}")
		injector.injectMeta.withProperty("og:url"	).withContent(absPageUrl.encode)
		injector.injectMeta.withProperty("og:image"	).withContent(ogimage.encode)
		
		// ---- Open Graph Meta ---- Optional
		injector.injectMeta.withProperty("og:description"	).withContent(fandocUri.pod.summary)
		injector.injectMeta.withProperty("og:locale"		).withContent("en_GB")
		injector.injectMeta.withProperty("og:site_name"		).withContent("Fantom Pod Repository")
		
		metaDesc := "${pod.projectName} by ${pod.meta.orgName ?: pod.owner.screenName} :: ${pod.summary}"
		injector.injectMeta.withName("description").withContent(metaDesc)

	}

	RepoPod pod() {
		fandocUri.pod
	}

	Str aboutHtml() {
		fandocUri.aboutHtml
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
