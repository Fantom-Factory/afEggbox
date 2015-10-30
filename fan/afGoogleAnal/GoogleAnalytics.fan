using afIoc
using afIocConfig
using afDuvet

** (Service) - 
** Renders the Google Universal Analytics script and sends page views and events.
const mixin GoogleAnalytics {

	** Returns the domain used to setup the google script. 
	abstract Str? accountDomain()

	** Returns the account used to setup the google script. 
	abstract Str accountNumber()

	** Sends a page view to google analytics. If 'url' is given then it should start with a leading '/', e.g. `/about`
	abstract Void sendPageView(Uri? url := null)

	** Sends a event to google analytics. 
	abstract Void sendEvent(Str category, Str action, Str? label := null)
}

internal const class GoogleAnalyticsImpl : GoogleAnalytics {
	@Inject	private const Log log
	
	@Config { id="afGoogleAnalytics.accountNumber" }
	@Inject	override const Str accountNumber

	@Config { id="afGoogleAnalytics.accountDomain" }
	@Inject	private const Uri googleDomain

	@Config { id="afBedSheet.host" }
	@Inject	private const Uri bedSheetHost

	@Config { id="afIocEnv.isProd" }
	@Inject	private const Bool? isProd

	@Inject	private const HtmlInjector	injector
			private const Bool 			renderScripts
			override const Str? 		accountDomain

	new make(|This|in) {
		in(this)

		borked := false
		if (accountNumber.isEmpty) {
			log.warn("Google Analytics Account Number has not been set.\n Add the following to your AppModule's contributeApplicationDefaults() method:\n   config[${GoogleAnalyticsConfigIds#.name}.${GoogleAnalyticsConfigIds#accountNumber.name}] = \"GA-ACC-NO\");")
			borked = true
		}
		if (isProd && (accountDomain == null || accountDomain.lower.contains("localhost"))) {
			log.warn("Google Analytics Domain `${accountDomain}` is not valid'!\n Add the following to your AppModule's contributeApplicationDefaults() method:\n   config[${GoogleAnalyticsConfigIds#.name}.${GoogleAnalyticsConfigIds#accountDomain.name}] = \"http://www.example.com\");")
			borked = true
		}
		renderScripts = isProd && !borked
		
		accountDomain = googleDomain.toStr.isEmpty ? bedSheetHost.host : googleDomain.host 
	}
	
	override Void sendPageView(Uri? url := null) {
		renderGuas
		injector.injectScript.withScript(url == null ? "ga('send', 'pageview');" : "ga('send', 'pageview', '${url.encode}');")
	}

	override Void sendEvent(Str category, Str action, Str? label := null) {
		renderGuas
		jsCategory	:= category.toCode('\'')
		jsAction	:= action.toCode('\'')
		jsLabel		:= label?.toCode('\'')
		injector.injectScript.withScript(label == null ? "ga('send', 'event', ${jsCategory}, ${jsAction});" : "ga('send', 'event', ${jsCategory}, ${jsAction}, ${jsLabel});")
	}
	
	private Void renderGuas() {
		injector.injectScript.withScript(
			"(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
			 (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
			 m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
			 })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
			 ga('create', '<%= accountNumber %>', '<%= accountDomain %>');")
	}
}
