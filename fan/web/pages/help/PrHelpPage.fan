using afIoc
using afIocConfig
using afEfanXtra

@Abstract
const mixin PrHelpPage : PrPage {
	
	@Inject abstract FandocWriter	fandocWriter
	@Config { id="afBedSheet.host" }
	@Inject abstract Uri			host

	@BeforeRender
	Void beforeRender() {
		injector.injectRequireModule("anchorJS", null, ["article h2, article h3, article h4"])
	}

	Str printFandocHelp(Uri name) {
		// FIXME: also read from pod 
		fandocFile := `etc/web-pages/help/${name}`.toFile
		return fandocWriter.writeStrToHtml(fandocFile.readAllStr, LinkResolverCtx())
	}

	Str printFandocRaw(Uri name) {
		fandocFile := `etc/web-pages/help/${name}`.toFile
		return fandocFile.readAllStr.toXml
	}
}
