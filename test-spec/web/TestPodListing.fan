using afIoc
using afFancordion

** Pod Listing
** ###########
** 
** Example
** -------
** 
**   table:
**   row+exe:createPod(#COL[0], #COL[1], #COL[2], #COL[3])
** 
**   Name   Version  User   Public
**   -----  -------  ----   ----
**   afIoc  1.69     micky  true
**   afIoc  2.6      micky  true
**   poo    1.00     mouse  true
**   poo    1.0.1    mouse  true
**   foo    1.2      mouse  false
**   foo    1.3      mouse  false
** 
** When I list the [public pods]`exe:listPublicPods` I should see:
**
**   table:
**   verifyRows:pods
** 
**   Name   Version
**   -----  -------
**   afIoc  2.6
**   poo    1.0.1
** 
** When I list the [private pods for mouse]`exe:listPrivatePods` I should see:
** 
**   table:
**   verifyRows:pods
** 
**   Name   Version
**   -----  -------
**   foo    1.3
**   poo    1.0.1
** 
** When I list the [public pods for mouse]`exe:listPublicPodsForUser` I should see:
** 
**   table:
**   verifyRows:pods
** 
**   Name   Version
**   -----  -------
**   afIoc  2.6
**   foo    1.3
**   poo    1.0.1
** 
@Fixture { failFast=false }
class TestPodListing : WebFixture {

	Str[][]? 	pods
	
	Str:Str podMeta := [
		"pod.summary" : "Stuff",
		"pod.depends" : "sys 1.0",
		"build.ts"	  : "2006-06-06T06:06:00Z UTC",
		"vcs.uri"	  : "wotever",
		"licence.name": "wotever"
	]
	
	Void createPod(Str name, Str version, Str email, Str isPublic) {
		user := getOrMakeUser(email)
		pod  := makePod(podMeta.setAll([
			"pod.name"    : name,
			"pod.version" : version,
			"repo.public" : isPublic
		]), |Zip zip| {
			zip.writeNext(`/doc/pod.fandoc`)
		})
		scope.registry.activeScope.createChild("request") {
			fanrRepo.publish(user, pod.in)
		}
	}
	
	Void listPublicPods() {
		pods = podDao.findLatestPods.map { Str[it.name, it.version.toStr] }
	}

	Void listPrivatePods() {
		user := getOrMakeUser("mouse")
		userSession.loginRequestAs(user)
		pods = podDao.findLatestPods(user).map { Str[it.name, it.version.toStr] }
		userSession.logout
	}

	Void listPublicPodsForUser() {
		user := getOrMakeUser("mouse")
		userSession.loginRequestAs(user)
		pods = podDao.findLatestPods.map { Str[it.name, it.version.toStr] }
		userSession.logout
	}
	
	private Buf makePod(Str:Str meta, |Zip|? f := null) {	
		podBuf := Buf()
		zip := Zip.write(podBuf.out)
		zip.writeNext(`meta.props`).writeProps(meta, true)
		f?.call(zip)
		zip.close
		return podBuf.flip
	}
}
