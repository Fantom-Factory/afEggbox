using afIoc
using afIocEnv
using afBounce
using afFancordion

class RepoRunner : FancordionRunner {
    private BedServer? server

    new make() {
        outputDir = `fancordion-results/`.toFile
		skinType = afFancordionBootstrap::BootstrapSkin#
    }

    override Void suiteSetup() {
        super.suiteSetup
        server = BedServer("afEggbox").addModule(WebTestModule#).startup		
    }

    override Void suiteTearDown(Type:FixtureResult resultsCache) {
        server?.shutdown
        super.suiteTearDown(resultsCache)
    }

    override Void fixtureSetup(Obj fixtureInstance) {
        webFixture := ((RepoFixture) fixtureInstance)

        super.fixtureSetup(fixtureInstance)
        webFixture.client = server.makeClient
        server.injectIntoFields(webFixture)
        webFixture.setupFixture
    }

    override Void fixtureTearDown(Obj fixtureInstance, FixtureResult result) {
        webFixture := ((RepoFixture) fixtureInstance)

        webFixture.tearDownFixture
        super.fixtureTearDown(fixtureInstance, result)
    }
}

const class WebTestModule {

    @Override
    static IocEnv overrideIocEnv() {
        IocEnv.fromStr("Testing")
    }

    // other test specific services and overrides...
}
