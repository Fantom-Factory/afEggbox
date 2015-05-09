using afIoc

** Pod Publishing : Failures
** #########################
** 
** Example
** -------
** 
**  - [Pod exceeds maximum size of 100B]`errMsg:testPodSizeTooBig`
**  - [Pod name 'acmeWidgets' has already been taken by user 'stevie']`errMsg:testPodNameTakenBySomeoneElse`
**  - [Pod version '1.1.1' is too small, it must be at least '2.3.4']`errMsg:testPodVersionTooSmall`
**  - [Pods must define meta data for 'pod.summary']`errMsg:testMissingPodMeta`
**  - [Public pods must define meta data for 'licence.name' or 'license.name']`errMsg:testMissingPublicPodMeta`
**  - [Public pods must contain the file '/doc/pod.fandoc'.]`errMsg:testMissingPublicPodFandoc`
** 
class TestPodPublishingFailures : WebFixture {

	@Inject private Registry? reg
	@Inject private FanrRepo? repo
	
	Str:Str podMeta := [
		"pod.name"    : "acmeWidgets",
		"pod.version" : "0.0.5",
		"pod.summary" : "Widgets for me!",
		"pod.depends" : "sys 1.0",
		"build.ts"	  : "2006-06-06T06:06:00Z UTC",
		"private"	  : "true"
	]
	
	Void testPodSizeTooBig() {
		setupFixture
		repo := (FanrRepo) reg.autobuild(FanrRepo#, null, [FanrRepo#maxPodSize : 100])
		buf  := Buf().writeChars("".padl(100))
		repo.publish(newUser, buf.flip.in)
	}

	Void testPodNameTakenBySomeoneElse() {
		setupFixture
		// an old private pod
		repo.publish(newUser(`stevie@abc.com`), makePod(podMeta.setAll([
			"pod.name"    : "acmeWidgets",
			"pod.version" : "0.0.5",
			"pod.summary" : "Widgets for me!"
		])).in)

		// a new public pod
		repo.publish(newUser(`steveo@abc.com`), makePod(podMeta.setAll([
			"pod.name"    : "acmeWidgets",
			"pod.version" : "0.0.2",
			"pod.summary" : "Widgets for everyone!"
		])).in)
	}

	Void testPodVersionTooSmall() {
		setupFixture
		repo.publish(newUser, makePod(podMeta.setAll([
			"pod.version" : "0.1.2",
		])).in)
		repo.publish(newUser, makePod(podMeta.setAll([
			"pod.version" : "1.2.3",
		])).in)
		repo.publish(newUser, makePod(podMeta.setAll([
			"pod.version" : "2.3.4",
		])).in)

		repo.publish(newUser, makePod(podMeta.setAll([
			"pod.version" : "1.1.1",
		])).in)
	}

	Void testMissingPodMeta() {
		setupFixture
		repo.publish(newUser, makePod([
			"pod.name"    : "acmeWidgets",
			"pod.version" : "0.0.5",
			"pod.depends" : "sys 1.0",
			"build.ts"	  : "2006-06-06T06:06:00Z UTC",
			"private"	  : "true"
		]).in)
	}

	Void testMissingPublicPodMeta() {
		setupFixture
		repo.publish(newUser, makePod([
			"pod.name"    : "acmeWidgets",
			"pod.version" : "0.0.5",
			"pod.depends" : "sys 1.0",
			"pod.summary" : "Widgets for everyone!",
			"build.ts"	  : "2006-06-06T06:06:00Z UTC",
			"repo.public"  : "true"
		], |Zip zip| {
			zip.writeNext(`/doc/pod.fandoc`)
		}).in)
	}

	Void testMissingPublicPodFandoc() {
		setupFixture
		repo.publish(newUser, makePod([
			"pod.name"    : "acmeWidgets",
			"pod.version" : "0.0.5",
			"pod.depends" : "sys 1.0",
			"pod.summary" : "Widgets for everyone!",
			"build.ts"	  : "2006-06-06T06:06:00Z UTC",
			"repo.public"  : "true",
			"license.name": "pfft",
			"vcs.uri"	  : "pfft",
		]).in)
	}
	
	Buf makePod(Str:Str meta, |Zip|? f := null) {	
		podBuf := Buf()
		zip := Zip.write(podBuf.out)
		zip.writeNext(`meta.props`).writeProps(meta, true)
		f?.call(zip)
		zip.close
		return podBuf.flip
	}
}
