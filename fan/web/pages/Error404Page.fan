using afPillow
using afEfanXtra
using afIoc
using afIocConfig

@Page { disableRoutes=true }
const mixin Error404Page : PrPage {
		
	@Config { id="afGoogleAnalytics.accountNumber" }
	@Inject	abstract Str accountNumber

	@Config { id="afGoogleAnalytics.accountDomain" }
	@Inject	abstract Uri googleDomain

	@Config { id="afBedSheet.host" }
	@Inject	abstract Uri bedSheetHost

	@Config { id="afIocEnv.isProd" }
	@Inject	abstract Bool? isProd

	@InitRender
	Void initRender() {
		injector.injectRequireModule("notFound")
	}

	Bool renderGa() {
		borked := false
		
		if (accountNumber.isEmpty)
			borked = true
		
		if (isProd && (accountDomain == null || accountDomain.lower.contains("localhost")))
			borked = true
		
		return isProd && !borked
	}
	
	Str? accountDomain() {
		return googleDomain.toStr.isEmpty ? bedSheetHost.host : googleDomain.host
	}
}
