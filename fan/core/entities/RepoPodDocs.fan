using afIoc
using afMorphia
using fandoc

@Entity { name = "podDocs" }
class RepoPodDocs {
	@Property {}	Str		_id
	@Property {}	Uri:Buf	contents
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Uri:Buf contents) {
		RepoPodDocs {
			it._id		= pod._id
			it.contents	= contents
		}
	}
	
	Str podDoc() {
		contents[`/doc/pod.fandoc`].readAllStr
	}
	
	Uri[] pages() {
		contents.keys.findAll { it.ext == "fandoc" }
	}
	
	Uri? resolveDoc(Uri key) {
		path := key.ext == null ? key.pathStr + ".fandoc" : key.pathStr 
		return contents.keys.find { it.toStr.equalsIgnoreCase(path) }
	}

	Heading[] findHeadings(Uri key) {
		echo("### $key")
		echo("### ${fandoc(key)?.findHeadings}")
		return fandoc(key)?.findHeadings ?: Heading#.emptyList
	}

	Str? resolveHeading(Uri key, Str headingId) {
		heading	:= fandoc(key).findHeadings.find { (it.anchorId ?: it.title.fromDisplayName).equalsIgnoreCase(headingId) }
		return heading.anchorId ?: heading.title.fromDisplayName
	}
	
	Doc? fandoc(Uri key) {
		if (key.ext != "fandoc")
			return null
		content := get(key)
		if (content == null)
			return null
		// FIXME: use Fandoc service
		return FandocParser().parseStr(content.readAllStr)
	}

	@Operator
	Buf? get(Uri fileUri) {
		contents[fileUri]?.seek(0)
	}
}
