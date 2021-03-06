using afIoc
using afFancordion

** Pod Publishing : Failures
** #########################
** 
** Example
** -------
**  - [Pod exceeds maximum size of 100B]`errMsg:podSizeTooBig`
**  - [Pod name 'acmeWidgets' has already been taken by user 'Stevie']`errMsg:podNameTakenBySomeoneElse`
**  - [Pod version '1.1.1' must be greater than '2.3.4']`errMsg:podVersionTooSmall`
**  - [Pods must define meta data for 'pod.summary']`errMsg:missingPodMeta`
**  - [Public pods must define meta data for 'licence.name' or 'license.name']`errMsg:missingPublicPodMeta`
** 
@Fixture { failFast = false }
class TestPodPublishingFailures : WebFixture {
**  - [Public pods must contain the file '/doc/pod.fandoc'.]`errMsg:missingPublicPodFandoc`

	@Inject private FanrRepo?	repo
	
	Str:Str podMeta := [
		"pod.name"    : "acmeWidgets",
		"pod.version" : "0.0.5",
		"pod.summary" : "Widgets for me!",
		"pod.depends" : "sys 1.0",
		"build.ts"	  : "2006-06-06T06:06:00Z UTC",
		"private"	  : "true",
		"licence.name": "MIP",
		"vcs.uri"	  : "wotever"
	]
	
	Void podSizeTooBig() {
		setupFixture
		repo := (FanrRepo) scope.build(FanrRepo#, null, [FanrRepo#maxPodSize : 100])
		buf  := Buf().writeChars("".padl(100))
		scope.registry.activeScope.createChild("httpRequest") {
			repo.publish(newUser, buf.flip.in)
		}
	}

	Void podNameTakenBySomeoneElse() {
		setupFixture
		// an old private pod
		scope.registry.activeScope.createChild("httpRequest") {
			repo.publish(getOrMakeUser("stevie@abc.com"), makePod(podMeta.setAll([
				"pod.name"    : "acmeWidgets",
				"pod.version" : "0.0.5",
				"pod.summary" : "Widgets for me!"
			])).in)

			// a new public pod
			repo.publish(getOrMakeUser("steveo@abc.com"), makePod(podMeta.setAll([
				"pod.name"    : "acmeWidgets",
				"pod.version" : "0.0.2",
				"pod.summary" : "Widgets for everyone!"
			])).in)
		}
	}

	Void podVersionTooSmall() {
		setupFixture
		scope.registry.activeScope.createChild("httpRequest") {
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
	}

	Void missingPodMeta() {
		setupFixture
		scope.registry.activeScope.createChild("httpRequest") {
			repo.publish(newUser, makePod([
				"pod.name"    : "acmeWidgets",
				"pod.version" : "0.0.5",
				"pod.depends" : "sys 1.0",
				"build.ts"	  : "2006-06-06T06:06:00Z UTC",
				"private"	  : "true"
			]).in)
		}
	}

	Void missingPublicPodMeta() {
		setupFixture
		scope.registry.activeScope.createChild("httpRequest") {
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
	}

	Void missingPublicPodFandoc() {
		setupFixture
		scope.registry.activeScope.createChild("httpRequest") {
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
