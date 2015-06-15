using afIoc
using afIocConfig
using afEfanXtra
using afBedSheet

const mixin AboutPage : PrPage {

	@Inject abstract FandocWriter	fandocWriter
	@Config
	@Inject abstract Bool			aboutFandocExists

	@InitRender
	Void initRender() {
		if (!aboutFandocExists)
			throw HttpStatusErr(404)
	}
	
	Str printFandocAbout() {
		fandocFile := `etc/web-pages/about.fandoc`.toFile
		return fandocWriter.writeStrToHtml(fandocFile.readAllStr, LinkResolverCtx())
	}	
}
