using afBounce
using afFancordion
using afIoc

** The super class for all Web Fixtures
abstract class RepoFixture : FixtureTest {
    BedClient? client

	@Inject {}	RepoPodDao?			podDao
	@Inject {}	RepoPodFileDao?		podFileDao
	@Inject {}	RepoUserDao?		userDao
	@Inject {}	FanrRepo?			fanrRepo

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
	
	RepoUser getOrMakeUser(Str email) {
		existing := userDao.getByEmail(email.toUri, false)
		return (existing != null) ? existing : userDao.create(newUser(email.toUri))
	}

	@Deprecated
	RepoUser createOrUpdateUser(RepoUser user) {
		existing := userDao.getByEmail(user.email, false)
		if (existing != null)
			user = userDao.update(existing)
		else
			user = userDao.create(user)
		return user
	}
}
