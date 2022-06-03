using afIoc
using afIocEnv
using afBounce
using afFancordion
using afMorphia

class Migration {

	BedServer? server
	
	@Inject { type=RepoPod# } Datastore? podDao
	
	new make(|This| f) { f(this) }

	
	Void go() {
		echo("GOGOGO!!!")
		q := Query()
		podDao.query(q).findAll.each |RepoPod pod| {
			vers := pod.meta.version.segments.rw
			while (vers.size < 4)
				vers.add(0)
			pod.podName = pod.meta.name
			pod.podVersion	= vers
			echo(pod._id)
			pod.save
		}
		
	}
	
	
	static Void main(Str[] args) {
		server		:= BedServer("afEggbox").addModule(WebTestModule#).startup	
		migration	:= (Migration) server.build(Migration#)
		migration.server = server
		migration.go
		server.shutdown
	}
}
