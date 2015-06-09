using afIoc
using afMorphia
using fandoc

@Entity { name = "podDocs" }
class RepoPodDocs {
	@Property private Str			_id
	@Property private [Uri:Str]?	txt
	@Property private [Uri:Buf]?	bin
	
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
			it._id	= pod._id
			it.txt	= txt.isEmpty ? null : txt
			it.bin	= bin.isEmpty ? null : bin
		}
	}
	
	Uri:Str fandocPages() {
		txt?.findAll |v, k| {
			k.ext == "fandoc"
		} ?: Uri:Str[:]
	}
	
	@Operator
	Buf? get(Uri fileUri, Bool checked := true) {
		(bin?.get(fileUri)?.seek(0) 
			?: txt?.get(fileUri)?.toBuf)
				?: (checked ? throw Err("Pod doc `$fileUri` not found") : null)
	}
}
