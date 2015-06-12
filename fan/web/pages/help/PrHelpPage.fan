using afIoc
using afEfanXtra

@Abstract
const mixin PrHelpPage : PrPage {
	
	@Inject abstract FandocWriter	fandocWriter

	@BeforeRender
	Void beforeRender() {
		injector.injectRequireModule("anchorJS", null, ["article h2, article h3, article h4"])
	}

	Str printFandocHelp(Uri name) {
		// FIXME: also read from pod 
		fandocFile := `etc/web-pages/help/${name}`.toFile
		return fandocWriter.writeStrToHtml(fandocFile.readAllStr, LinkResolverCtx())
	}
}
