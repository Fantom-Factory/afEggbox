
** A list of required config values.
const mixin GoogleAnalyticsConfigIds {

	 ** Your Google account number, usually in the form of 'UA-XXXXX-X'.
	 ** **Required!**
	static const Str accountNumber 	:= "afGoogleAnalytics.accountNumber";

	 ** Your Google account domain (uri), in the format 'http://wotever.com'. 
	 ** If not supplied, it is taken from the BedSheet 'host' config value.
	 ** 
	 ** Example: '//example.org/' or 'http://example.org/'
	static const Str accountDomain 	:= "afGoogleAnalytics.accountDomain";

}
