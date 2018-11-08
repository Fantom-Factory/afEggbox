using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using afGoogleAnalytics::GoogleAnalytics
using afConcurrent::AtomicMap
using gfx::Size
using [java] fanx.interop::Interop								as JInterop
using [java] javax.imageio::ImageIO								as JImageIO
using [java] javax.imageio::ImageReader							as JImageReader
using [java] javax.imageio.stream::MemoryCacheImageInputStream	as JImageInputStream

@Page { disableRouting = true }
const mixin PodSummaryPage : PrPage {
	private static const Unit	bytes		:= Unit("byte")
	private static const Unit[] units 		:= ["petabyte", "terabyte", "gigabyte", "megabyte", "kilobyte", "byte"].map { Unit(it) }

	private static const AtomicMap ogimageSizeCache	:= AtomicMap() { it.keyType=Uri#; it.valType=Size?#; }
	
	@Inject			abstract Scope				scope
	@Inject			abstract RepoPodDao			podDao
	@Inject			abstract SyntaxWriter		syntaxWriter
	@Inject			abstract EggboxConfig		eggboxConfig
	@Inject			abstract GoogleAnalytics	googleAnalytics
	@Inject			abstract CorePods			corePods
	@Inject			abstract ClientAssetCache	assetCache
	@PageContext	abstract FandocSummaryUri	fandocUri
					abstract RepoPod[][]		podVersions
					abstract RepoPod[]			referencedBy
					abstract Str:RepoPod		allPods
					abstract RepoPod?			pod
	
	@BeforeRender
	Void beforeRender() {
		pod = fandocUri.pod

		// redirect on dodgy name casing - this keeps GoogleAnalytics happy
		if (fandocUri.podName != pod.name)
			throw ReProcessErr(Redirect.movedTemporarily(pod.toSummaryUri.toClientUrl))

		podVersions = groupBy(podDao.findPodVersions(pod.name)) |RepoPod item->Version| {
			return Version([item.version.major, item.version.minor].exclude { it == null })
		}.vals
		injector.injectRequireModule("anchorJS", null, ["article h2, article h3, article h4"])
		injector.injectRequireScript(["jquery":"\$", "bootstrap":"bs"], "\$('.sideMenu').affix({ offset: { top: 70, bottom: function () { return (this.bottom = \$('#fatFooter').outerHeight(true)) } } })")

		if (eggboxConfig.googleAnalyticsEnabled)
			googleAnalytics.renderPageView(fandocUri.toSummaryUri.toClientUrl)
	
		allPods = Str:RepoPod[:].addList(podDao.findLatestPods(loggedInUser)) { it.name }
		referencedBy = allPods.vals.findAll |p| {
			p.dependsOn.any {
				it.name == pod.name && it.match(pod.version) 
			}
		}.sort |p1, p2| { p1.name <=> p2.name }
		
		deps := Str[][,]
		pod.dependsOn.each { addDeps(pod.name, it, deps) }
		deps = deps.unique.exclude { it[1] == "sys" }
		json := deps.unique.map { ["source":it[0], "target":it[1], "css":it[2]] }
		
		injector.injectRequireModule("podGraph", null, [pod.projectName, json])
	}
	
	private Void addDeps(Str source, Depend target, Str[][] deps) {
		if (corePods.isCorePod(target.name)) {
			src := allPods[source]?.projectName ?: source 
			deps.add(Str[src, target.name, source == pod.name ? "direct" : ""])
			corePods.depends(target.name).each {
				addDeps(target.name, it, deps)
			}
		} else {
			// test with BedSheet draft
			src := allPods[source]?.projectName ?: source 
			tPod := allPods[target.name]
			deps.add(Str[src, tPod?.projectName ?: target.name, source == pod.name ? "direct" : ""])
			tPod?.dependsOn?.each {
				addDeps(tPod.name, it, deps)				
			}
		}
	}

	** Need to wait until *after* layout has rendered to find the HTML tag.
	@AfterRender
	Void afterRender(StrBuf buf) {
		ogasset		:= fandocUri.toDocUri(`/doc/ogimage.png`)	// first lookg for PNG
		ogasset		 = ogasset.exists ? ogasset : fandocUri.toDocUri(`/doc/ogimage.jpg`)	// then look for JPG
		ogimage		:= ogasset.exists ? ogasset.toAsset.clientUrl : fileHandler.fromLocalUrl(`/images/defaultPodOgimage.png`).clientUrl
		htmlIndex	:= buf.toStr.index("<html ") + "<html ".size
		absPageUrl	:= bedServer.toAbsoluteUrl(fandocUri.toClientUrl)

		// ---- Open Graph Meta ---- Mandatory
		buf.insert(htmlIndex, "prefix=\"og: http://ogp.me/ns#\" ")
		injector.injectMeta.withProperty("og:type"	).withContent("website")
		injector.injectMeta.withProperty("og:title"	).withContent("${pod.projectName} ${pod.version}")
		injector.injectMeta.withProperty("og:url"	).withContent(absPageUrl.encode)
		injector.injectMeta.withProperty("og:image"	).withContent(bedServer.toAbsoluteUrl(ogimage).encode)
		
		// Facebook and Reddit want the ogimage size up front, so...
		ogsize := ogimageSizeCache.getOrAdd(ogimage) |->Size?| { getSize(ogimage) } as Size
		if (ogsize == null)
			ogimageSizeCache.remove(ogimage)
		else {
			injector.injectMeta.withProperty("og:image:width"	).withContent(ogsize.w.toStr)
			injector.injectMeta.withProperty("og:image:height"	).withContent(ogsize.h.toStr)
		}

		// ---- Open Graph Meta ---- Optional
		injector.injectMeta.withProperty("og:description"	).withContent(fandocUri.pod.meta.summary)
		injector.injectMeta.withProperty("og:locale"		).withContent("en_GB")
		injector.injectMeta.withProperty("og:site_name"		).withContent("Fantom Pod Repository")
		
		metaDesc := "${pod.projectName} by ${pod.meta.orgName ?: pod.owner.screenName} :: ${pod.meta.summary}"
		injector.injectMeta.withName("description").withContent(metaDesc)
	}

	** Not an easy task!
	**  - it's near impossible to mess with FWT ThreadLocals
	**  - calling the swt code direct requires we deploy 64-bit linux libs
	**  - when then throws exceptions 'cos its the wrong, unsupported, linux type!
	**  - standard AWT Java toolkit either requires a running Frame or returns -1 for width and height
	** 
	** So we're using ImageIO.
	** See http://stackoverflow.com/questions/672916/how-to-get-image-height-and-width-using-java#answer-2911772
	Size? getSize(Uri ogimage) {
		// note I'm passing a clientUri here, not a localUri - should be fine if were the root mod 
		oguri := ogimage.toStr.startsWith("/coldFeet") ? `/` + ogimage[2..-1] : ogimage // remove cold feet prefix
		idata := assetCache.getAndUpdateOrProduce(oguri)?.in?.readAllBuf

		if (idata != null) {
			iter := JImageIO.getImageReadersBySuffix(ogimage.ext)
			
			while (iter.hasNext) {
				try {
					reader := (JImageReader) iter.next
					reader.setInput(JImageInputStream(JInterop.toJava(idata.in)))
					width := reader.getWidth(reader.getMinIndex)
					height := reader.getHeight(reader.getMinIndex)
					reader.dispose
					return Size(width, height)
				} catch { }
			}
		}
		return null
	}
	
	Str installPodName() {
		fandocUri.isLatest ? pod.name : "\"${pod.name} ${pod.version}\""
	}

	Str installPodNameFpm() {
		fandocUri.isLatest ? pod.name : "\"${pod.name}@${pod.version}\""
	}
	
	Str podVersionRange() {
		return pod.version.segments.size > 2 
			? "${Version(pod.version.segments[0..2])} - ${Version(pod.version.segments[0..1])}"
			: pod.version.toStr
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
		podUrl := FandocUri.fromUri(scope, `fandoc:/${pod.name}`)?.toClientUrl

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
	
	static Obj:Obj[] groupBy(Obj[] list, |Obj item, Int index->Obj| keyFunc) {
		list.reduce(Obj:Obj[][:] { it.ordered = true}) |Obj:Obj[] bucketList, val, i| {
			key := keyFunc(val, i)
			bucketList.getOrAdd(key) { Obj[,] }.add(val)
			return bucketList
		}
	}
}

