using afIoc::Inject
using afBedSheet
using afEfanXtra
using afPillow
using afDuvet

@Abstract @Page
const mixin PrPage : PrComponent {

	@Inject abstract FandocWriter	fandocWriter
	@Inject	abstract Alert			alert

	Bool isActive() {
		this.typeof.fits(pageMeta.pageType) 
	}
	
	Str podsUrl() {
		pageUrl(PodsPage#)
	}
	
	Str printFandocHelp(Uri name) {
		// FIXME: also read from pod 
		fandocFile := `etc/web-pages/help/${name}`.toFile
		return fandocWriter.writeStrToHtml(fandocFile.readAllStr, LinkResolverCtx())
	}
}
