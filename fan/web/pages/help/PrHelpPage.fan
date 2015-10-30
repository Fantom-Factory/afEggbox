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

	Str printFandoc(Uri name) {
		fandocFile := name.relTo(`/`).toFile.exists ? name.relTo(`/`).toFile : typeof.pod.file(name)
		return fandocWriter.writeStrToHtml(fandocFile.readAllStr, LinkResolverCtx())
	}

	Str printFandocRaw(Uri name) {
		fandocFile := name.relTo(`/`).toFile.exists ? name.relTo(`/`).toFile : typeof.pod.file(name)
		return fandocFile.readAllStr.toXml
	}
}
