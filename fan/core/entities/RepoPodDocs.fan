using afIoc
using afMorphia
using fandoc

@Entity { name = "podDocs" }
class RepoPodDocs {
	@Property {} Str		_id
	@Property {} Uri:Str	textDocs
	@Property {} Uri:Buf	binaryDocs
	
	new make(|This|f) { f(this) }
	
	static new fromFile(RepoPod pod, Uri:Buf contents) {
		txt	:= Uri:Str[:]
		bin	:= Uri:Buf[:]
		contents.each |buf, uri| {
			if (uri.mimeType?.mediaType == "text")
				txt[uri] = buf.seek(0).readAllStr
			else
				bin[uri] = buf
		}
		
		return RepoPodDocs {
			it._id			= pod._id
			it.textDocs		= txt
			it.binaryDocs	= bin
		}
	}
	
	Uri:Str fandocPages() {
		textDocs.findAll |v, k| {
			k.ext == "fandoc"
		}
	}
	
	@Operator
	Buf? get(Uri fileUri, Bool checked := true) {
		(binaryDocs[fileUri]?.seek(0) 
			?: textDocs[fileUri]?.toBuf)
				?: (checked ? throw Err("Pod doc `$fileUri` not found") : null)
	}
}
