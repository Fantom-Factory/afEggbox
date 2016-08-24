using afBounce
using afFancordion::FixtureTest
using afFancordion::FancordionRunner
using afIoc

** The super class for all Web Fixtures
abstract class RepoFixture : FixtureTest {
    BedClient? client

	@Inject {}	RepoPodDao?			podDao
	@Inject {}	RepoPodFileDao?		podFileDao
	@Inject {}	RepoPodDocsDao?		podDocsDao
	@Inject {}	RepoPodApiDao?		podApiDao
	@Inject {}	RepoPodSrcDao?		podSrcDao
	@Inject {}	RepoUserDao?		userDao
	@Inject {}	FanrRepo?			fanrRepo
	@Autobuild	Indexes?			indexes

    virtual Void setupFixture() {
		podDao.dropAll
		podFileDao.dropAll
		podDocsDao.dropAll
		podApiDao.dropAll
		podSrcDao.dropAll
		userDao.dropAll
		indexes.ensureIndexes
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

	// TODO kill me an use something else
	RepoUser createOrUpdateUser(RepoUser user) {
		existing := userDao.getByEmail(user.email, false)
		if (existing != null)
			user = userDao.update(existing)
		else
			user = userDao.create(user)
		return user
	}
}
