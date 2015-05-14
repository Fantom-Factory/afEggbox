using afIoc
using afBedSheet
using afPillow

const class PodRoutes : Route {
	
	@Inject	private const HttpRequest	httpReq
	@Inject	private const Pages	 		pages
	@Inject	private const RepoPodDao	podDao

	new make(|This|in) { in(this) }
	
	** Returns a hint at what this route matches on. Used for debugging and in 404 / 500 error pages. 
	override Str matchHint() { "GET - /pods/***" }

	** Returns a hint at what response this route returns. Used for debugging and in 404 / 500 error pages. 
	override Str responseHint() { "Pod Pages" }

	override Obj? match(HttpRequest httpReq) {
		// FIXME: what of POST EVENTS?
		if (httpReq.httpMethod != "GET")
			return null

			// FIXME: what of Editing Public pods?

		
		reqPath := httpReq.url.pathOnly.path.rw
		pods	:= chomp(reqPath)
		if (pods != "pods")
			return null
		
		podName		:= chomp(reqPath)
		podVersion	:= Version((reqPath.isEmpty ? null : reqPath.first) ?: "", false)
		if (podVersion != null)	chomp(reqPath)
		podSection	:= chomp(reqPath)
		
		echo("podName - $podName")
		echo("podVersion - $podVersion")
		echo("podSection - $podSection")
		echo("extra - $reqPath")

		// --> /pods
		// --> /pods/
		if (podName == null)
			return pages.renderPage(PodsPage#)

		pod := podDao.findOne(podName, podVersion)
		if (pod == null) {
			v := (podVersion != null) ? " v${podVersion}" : ""
			return HttpStatus(404, "Pod ${podName}${v} not found")
		}

		// --> /pods/afSlim
		// --> /pods/afSlim/
		// --> /pods/afSlim/1.1.14
		// --> /pods/afSlim/1.1.14/
		if (podSection == null && reqPath.isEmpty)
			return pages.renderPage(PodSummaryPage#, [pod])
		
		// --> /pods/afSlim
		// --> /pods/afSlim/
		// --> /pods/afSlim/1.1.14
		// --> /pods/afSlim/1.1.14/
		if (podSection == "docs") {
			fileUrl := `/doc/` + ((podVersion == null) ? httpReq.url[3..-1] : httpReq.url[4..-1]).relTo(`/`)
			if (fileUrl == `/doc/`)
				fileUrl = fileUrl.plusName("pod.fandoc")
			// TODO: handle images and other files
			return pages.renderPage(PodDocsPage#, [pod, fileUrl])
		}
		
		return null
	}
	
	private Str? chomp(Str[] path) {
		path.isEmpty ? null : path.removeAt(0) 
	}
	
	private static const Int[] delims := ":/?#[]@\\".chars

	// Encode the Str *to* URI standard form
	// see http://fantom.org/sidewalk/topic/2357
	private static Str? encodeUri(Str? str) {
		if (str == null) return null
		buf := StrBuf(str.size + 8) // allow for 8 escapes
		str.chars.each |char| {
			if (delims.contains(char))
				buf.addChar('\\')
			buf.addChar(char)
		}
		return buf.toStr
	}
}
