using afIoc
using afPillow
using afEfanXtra
using afBedSheet
using afSitemap

@Page { contentType=MimeType("text/plain") }
const mixin PingPage : EfanComponent, SitemapExempt {
	@Inject abstract BedSheetServer bedServer
	
	override Str renderTemplate() {
		"OK
		 ${bedServer.appName} v${bedServer.appPod.version}
		 ${DateTime.now}"
	}
}
