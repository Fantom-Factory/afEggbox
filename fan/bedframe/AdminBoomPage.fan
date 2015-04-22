using afIoc
using afEfanXtra
using afBedSheet
using afSitemap
using afPillow

@Page { contentType = MimeType("application/xhtml+xml") }
const mixin AdminBoomPage : EfanComponent, SitemapExempt {

	@Inject abstract HttpRequest 	req
	@Inject abstract HttpResponse	res
	@Inject abstract BedSheetPages	bsPages
	@Inject abstract ErrEmailer		errEmailer

	@InitRender
	Void initRender() {
		auth := req.headers["Authorization"]
		
		if (auth == null)
			getOut(true)

		if (!auth.lower.startsWith("basic "))
			getOut(false)

		credentials := Buf.fromBase64(auth[6..-1]).readAllStr
		if (credentials != "SlimerDude:test1234")
			getOut(false)
	}
	
	private Void getOut(Bool askForCredentials) {
		if (askForCredentials)
			res.headers["WWW-Authenticate"] = "Basic realm=\"Fantom-Factory Admin\"" 
		throw HttpStatusErr(401, "Get out!")
	}

	override Str renderTemplate() {
		err := Err("BOOM! Yeah, baby! BOOOOOOM!")
		errEmailer.emailErr(err)
		return bsPages.renderErr(err, true).text 
	}
}
