using afIoc::Inject
using afIoc::Scope
using afIocEnv::IocEnv
using afBedSheet::ResponseProcessor
using afBedSheet::HttpRequest
using afBedSheet::HttpRequestHeaders
using afBedSheet::HttpResponse
using afBedSheet::HttpStatus
using afBedSheet::HttpRedirect
using afPillow
using web

const class PodPageProcessor : ResponseProcessor {
	
	@Inject	private const UserSession	userSession
	@Inject	private const Pages	 		pages
	@Inject	private const RepoPodDao	podDao
	@Inject private const Backdoor		backdoor
	@Inject private const Scope			scope
	@Inject private const AtomFeedPages	atomPages
	@Inject private const HttpRequest	httpReq
	@Inject private const HttpResponse	httpRes
	@Inject private const DirtyCash		dirtyCash
	@Inject private const IocEnv		iocEnv
	@Inject private const RepoPodDownloadDao	podDownloadDao

	new make(|This|in) { in(this) }
	
	override Obj process(Obj response) {
		reqPath := httpReq.url.pathOnly.path.rw
		pods	:= chomp(reqPath)
		if (pods != "pods")
			return HttpStatus(404)

		if (httpReq.httpMethod == "POST")
			return matchEvents(httpReq, reqPath) ?: HttpStatus(404)

		if (httpReq.httpMethod != "GET")
			return HttpStatus(405)

		podName		:= chomp(reqPath)
		if (podName == null)
			return pages.renderPage(PodsIndexPage#)
		
		if (reqPath.isEmpty && podName == "feed.atom")
			return atomPages.generateAll
		
		podVersion	:= Version((reqPath.isEmpty ? null : reqPath.first) ?: "", false)
		if (podVersion != null)	chomp(reqPath)
		podSection	:= chomp(reqPath)

		if (reqPath.isEmpty && podSection == "feed.atom")
			return atomPages.generateForPod(podName)			

		if (reqPath.size == 1 && podSection == "download" && reqPath.first == "${podName}.pod") {
			pod := podDao.findPod(podName, podVersion)
			podDownloadDao.create(RepoPodDownload(pod, "web", userSession.user))
			httpRes.saveAsAttachment("${pod.name}.pod")
			return PodDownloadAsset(pod.podFileDao, pod)
		}

		// --> /pods/afSlim/edit
		// --> /pods/afSlim/1.1.14/edit
		if (reqPath.isEmpty && podSection == "edit") {
			if (!userSession.isLoggedIn && backdoor.isOpen)
				backdoor.login

			if (userSession.isLoggedIn) {
				pod := podDao.findPod(podName, podVersion)
				if (pod == null) {
					v := (podVersion != null) ? " v${podVersion}" : ""
					return HttpStatus(404, "Pod ${podName}${v} not found")
				}

				if (userSession.user.owns(pod)) 
					return pages.renderPage(PodEditPage#, [pod])
				throw HttpStatus.makeErr(401, "Unauthorised")
			}
			throw HttpRedirect.movedTemporarilyErr(pages[LoginPage#].pageUrl)
		}

		fandocUri := FandocUri.fromClientUrl(scope, httpReq.url)
		if (fandocUri == null)
			return HttpStatus(404)
		
		return dirtyCash.cash |->Obj?| {
			if (fandocUri.validate == false) 
				return HttpStatus(404, "Could not validate: ${fandocUri.toUri.encode}")

			// don't cache pages when logged in so we can show the edit button and other confidential info 
			if (!userSession.isLoggedIn) {

				// set identity headers
				httpRes.headers.eTag 		  = fandocUri.etag
				httpRes.headers.lastModified = fandocUri.pod.builtOn.floor(1sec)	// 1 second which is the most precision that HTTP can deal with
		
				// check if we can return a 304 Not Modified
				if (notModified(httpReq.headers, fandocUri)) {
					// hitting CTRL+F5 in dev everytime is *really* annoying!
					if (!iocEnv.isDev) {
						httpRes.statusCode = 304
						return true
					}
				}
			}
	
			if (fandocUri is FandocSummaryUri)
				return pages.renderPage(PodSummaryPage#, [fandocUri])
	
			if (fandocUri is FandocDocUri) {
				fandocDocUri := (FandocDocUri) fandocUri 
				if (fandocDocUri.fileUri.ext == "fandoc")
					return pages.renderPage(PodDocPage#, [fandocUri])
				return fandocDocUri.toAsset
			}
			
			if (fandocUri is FandocSrcUri)
				return pages.renderPage(PodSrcPage#, [fandocUri])
			
			if (fandocUri is FandocApiUri)
				return (fandocUri as FandocApiUri).typeName == null
					? pages.renderPage(PodApiIndexPage#, [fandocUri])
					: pages.renderPage(PodApiPage#, [fandocUri])
			
			return null
		}
	}

	
	Obj? matchEvents(HttpRequest httpReq, Str[] reqPath) {
		podName		:= chomp(reqPath)
		podVersion	:= Version((reqPath.isEmpty ? null : reqPath.first) ?: "", false)
		if (podVersion != null)	chomp(reqPath)
		podSection	:= chomp(reqPath)
		
		// --> /pods
		// --> /pods/
		if (podName == null)
			return null

		pod := podDao.findPod(podName, podVersion)
		if (pod == null) {
			v := (podVersion != null) ? " v${podVersion}" : ""
			return HttpStatus(404, "Pod ${podName}${v} not found")
		}
		
		podEvent	:= chomp(reqPath)
		
		// --> /pods/afSlim/edit/save
		// --> /pods/afSlim/1.1.14/edit/save
		if (podSection == "edit" && podEvent == "save" && reqPath.isEmpty) {
			if (userSession.isLoggedIn) {
				if (userSession.user.owns(pod)) 
					return pages.callPageEvent(PodEditPage#, [pod], PodEditPage#onSave, null)
				throw HttpStatus.makeErr(401, "Unauthorised")
			}
			throw HttpRedirect.movedTemporarilyErr(pages[LoginPage#].pageUrl)
		}
		
		// --> /pods/afSlim/edit/delete
		// --> /pods/afSlim/1.1.14/edit/delete
		if (podSection == "edit" && podEvent == "delete" && reqPath.isEmpty) {
			if (userSession.isLoggedIn) {
				if (userSession.user.owns(pod)) 
					return pages.callPageEvent(PodEditPage#, [pod], PodEditPage#onDelete, null)
				throw HttpStatus.makeErr(401, "Unauthorised")
			}
			throw HttpRedirect.movedTemporarilyErr(pages[LoginPage#].pageUrl)
		}
		
		// --> /pods/afSlim/edit/validate
		// --> /pods/afSlim/1.1.14/edit/validate
		if (podSection == "edit" && podEvent == "validate" && reqPath.isEmpty) {
			if (userSession.isLoggedIn) {
				if (userSession.user.owns(pod)) 
					return pages.callPageEvent(PodEditPage#, [pod], PodEditPage#onValidate, null)
				throw HttpStatus.makeErr(401, "Unauthorised")
			}
			throw HttpRedirect.movedTemporarilyErr(pages[LoginPage#].pageUrl)
		}
		
		return null
	}

	
	private Str? chomp(Str[] path) {
		path.isEmpty ? null : path.removeAt(0) 
	}
	
	private static const Int[] delims := ":/?#[]@\\".chars

	// Encode the Str *to* URI standard form
	// see http://fantom.org/forum/topic/2357
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
	
	** Check if the request passed headers indicating it has cached version of the file. Return 
	** 'true' If the file has not been modified.
	** 
	** This method supports ETag "If-None-Match" and "If-Modified-Since" modification time.
	virtual Bool notModified(HttpRequestHeaders headers, FandocUri fandocUri) {
		// check If-Match-None
		matchNone := headers.ifNoneMatch
		if (matchNone != null) {
			if (WebUtil.parseList(matchNone).map |str->Str| {
				try   return WebUtil.fromQuotedStr(str)
				catch return str
			}.any { it == fandocUri.etag || it == "*" })
				return true
		}
		
		// check If-Modified-Since
		since := headers.ifModifiedSince
		if (since != null) {
			if (fandocUri.pod.builtOn.floor(1sec) <= since)
				return true
		}
	
		// gotta do it the hard way
		return false
	}
}

internal const class PodPageResponse {
	override Str toStr() {
		"Pod Pages"
	}
}
