using afIoc
using afFancordion
using afBounce

** Smoke Test
** ##########
**
** Example
** -------
** 1. Goto [Signup Page]`exe:showPage(#TEXT)` 
** 1. Enter an email address of [micky.mouse@disney.com]`set:input("#email").value` and a password of [password]`set:input("#password").value`
** 1. Click [Sign Up]`exe:click(#TEXT)`
** 1. Goto [My Pods Page]`exe:showPage(#TEXT)` 
** 1. Upload [poo-1.0.pod]`exe:uploadPod(#TEXT)`
** 1. [poo]`eq:myPodsEntry` is in the My Pods table
** 1. Goto the [Pods Index Page]`exe:showPage(#TEXT)`
** 1. [poo 1.0 by Micky Mouse]`eq:allPodsEntry` is in the All Pods table
** 1. View [/pods/poo/]`exe:gotoUrl(#TEXT)`
** 1. View [/pods/poo/api/]`exe:gotoUrl(#TEXT)`
** 1. View [/pods/poo/api/Bar]`exe:gotoUrl(#TEXT)`
** 1. View [/pods/poo/doc/]`exe:gotoUrl(#TEXT)`
** 1. View [/]`exe:gotoUrl(#TEXT)`
** 1. View [/sitemap.xml]`exe:gotoUrl(#TEXT)`
** 1. View [/pods/feed.atom]`exe:gotoUrl(#TEXT)`
class TestSmoke : WebFixture {

	Void uploadPod(Str podName) {
		// TODO can't post multi-part forms yet 
		user := userDao.getByEmail(`micky.mouse@disney.com`)
		scope.registry.activeScope.createChild("httpRequest") {
			fanrRepo.publish(user, `test/res/${podName}`.toFile.in)
		}
		showPage("MyPodsPage")
	}
	
	Str myPodsEntry() {
		Element("table td")[0].text
	}
	
	Str allPodsEntry() {
		Element(".media h4")[0].text
	}
	
	Void gotoUrl(Str url) {
		client.get(url.toUri)
	}
	
}
