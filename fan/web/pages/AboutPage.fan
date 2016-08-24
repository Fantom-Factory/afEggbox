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
			throw HttpStatus.makeErr(404)
		injector.injectRequireModule("anchorJS", null, ["article h2, article h3, article h4"])
	}

	Str printFandoc(Uri name) {
		fandocFile := name.relTo(`/`).toFile
		return fandocWriter.writeStrToHtml(fandocFile.readAllStr, LinkResolverCtx())
	}
}
