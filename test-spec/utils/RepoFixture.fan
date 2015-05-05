using afBounce
using afFancordion
using afIoc

** The super class for all Web Fixtures
abstract class RepoFixture : FixtureTest {
    BedClient? client

	@Inject {}	RepoPodDao?			podDao
	@Inject {}	RepoPodFileDao?		podFileDao
	@Inject {}	RepoUserDao?		userDao

    virtual Void setupFixture() {
		podDao.dropAll
		podFileDao.dropAll
		userDao.dropAll
    }

    virtual Void tearDownFixture() { }

    // The important bit - this creates the FancordionRunner to be used.
    override FancordionRunner fancordionRunner() {
        RepoRunner()
    }

	RepoUser newUser(Uri email := `Wotever`, Str password := "password") {
		RepoUser(email, password)
	}
	

	Void createOrUpdateUser(RepoUser user) {
		existing := userDao.findByEmail(user.email)
		if (existing != null)
			userDao.delete(existing)
		userDao.create(user)
	}
}
