using afIoc
using afIocConfig::FactoryDefaults

** The [Ioc]`pod:afIoc` module class.
@NoDoc
const class GoogleAnalyticsModule {

	internal static Void defineServices(ServiceDefinitions bob) {
		bob.add(GoogleAnalytics#)
	}

	@Contribute { serviceType=FactoryDefaults# }
	internal static Void contributeFactoryDefaults(Configuration config) {
		config[GoogleAnalyticsConfigIds.accountNumber]	= ""
		config[GoogleAnalyticsConfigIds.accountDomain]	= ``
	}
}
