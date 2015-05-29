using xml::XNs
using afIoc
using afIocConfig
using afAtom
using afSlim::TagStyle

const class AtomFeedGenerator {
	
	@Config { id="afBedSheet.host" }
	@Inject private const Uri host
	
	new make(|This|in) { in(this) }
	
	Str generate(Uri feedUrl, RepoPod[] pods, Str title, Str subTitle, Str altTitle) {
		podWrappers := (AtomPodWrapper[]) pods.map { AtomPodWrapper(it, host) }

		feed := Feed(host + feedUrl, Text(title), podWrappers.getSafe(0)?.updated ?: DateTime.now)
		feed.subtitle	= Text(subTitle) 
//		feed.icon		= `/favicons/favicon-96x96.png`	// TODO: feed icon
		
		afAtom := Pod.find("afAtom")
		feed.generator	= Generator(afAtom.name) {
			it.version	= afAtom.version.toStr
			it.uri		= `http://www.fantomfactory.org/pods/afAtom`
		}
		
		feed.links.add(Link(feedUrl, "self") {
			it.title	= title
			it.type		= MimeType("application/atom+xml")
		})

		feed.links.add(Link(feedUrl.parent, "alternate") {
			it.title	= altTitle
			it.type		= MimeType("text/html")
		})
		
		feed.categories.add(Category("fantom") {
			it.label	= "Fantom"
		})		
		
		feed.entries = podWrappers.map { it.toEntry }
		
		// Remove trailing slash from host to prevent double slashes when absolute URIs are appended on feed clients, e.g. `www.ff.org//content`
		// The problem is, URI adds it automatically! --> Env.cur.err.printLine(`http://www.dude.com`) --> http://www.dude.com/ 
		feedXml	:= feed.toXml
		base 	:= host.toStr.endsWith("/") ? host.toStr[0..-2] : host.toStr
		feedXml.root.addAttr("base", base, XNs("xml", ``)) 

		return feedXml.writeToStr
	}
}

mixin AtomEntryWrapper {
	abstract DateTime updated()
	abstract Entry toEntry()
	
	abstract Uri clientUrl()
	abstract Str title()
	abstract Str summary()
	
	override Int compare(Obj obj) {
		updated <=> ((AtomEntryWrapper) obj).updated
	}	
}

class AtomPodWrapper : AtomEntryWrapper {
			 RepoPod	pod
			 Uri		host
	override Str		title
	override Str		summary
	override Uri		clientUrl
	override DateTime	updated
	
	new make(RepoPod pod, Uri host) {
		this.pod 		= pod
		this.host		= host
		this.title		= "${pod.projectName} ${pod.version}"
		this.summary	= pod.summary
		this.clientUrl	= pod.toSummaryUri.toClientUrl
		this.updated	= pod.builtOn
	}

	override Entry toEntry() {
		entry := Entry(host + clientUrl, Text("${pod.projectName} v${pod.version} Released!"), updated)
		
		if (pod.meta.orgName != null)
			entry.authors.add(Person(pod.meta.orgName) {
				it.uri	= pod.meta.orgUrl
			})
		
		if (pod.meta.projectUrl != null)
			entry.links.add(Link(pod.meta.projectUrl, "alternate") {
				it.title	= pod.projectName
				it.type		= MimeType("text/html")
			})
		
		entry.categories.add(Category(pod.name) {
			it.label	= pod.projectName
		})
		
		pod.meta.tags?.split(',')?.each |tag| {
			entry.categories.add(Category(tag) {
				it.label	= tag.toDisplayName
			})
		}

		entry.content = Content.makeFromText(pod.toSummaryUri.aboutHtml, TextType.html)
		
		return entry
	}
}
