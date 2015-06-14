using afIoc
using afBedSheet

const class PodAssetProducer : ClientAssetProducer {
	
	@Inject private const DirtyCash	dirtyCash
	@Inject private const Registry	registry
	
	new make(|This|in) { in(this) }
	
	override ClientAsset? produceAsset(Uri localUrl) {
		dirtyCash.cash |->Obj?| {
			fandocUri := FandocUri.fromClientUrl(registry, localUrl)
			if (fandocUri isnot FandocDocUri)
				return null
			if (!fandocUri.validate)
				return null
			fandocDocUri := (FandocDocUri) fandocUri
			if (!fandocDocUri.isAsset)
				return null
			return fandocDocUri.toAsset
		}
	}
}
 
const class FandocDocAsset : ClientAsset {
			 const 	FandocDocUri	fandocUri
	override const 	Bool			exists		:= true
	override const 	DateTime?		modified 
	override const 	Int?			size 
	override const 	MimeType?		contentType

	new make(FandocDocUri fandocUri, |This|? in) : super(in) {
		this.fandocUri 	= fandocUri
		this.modified	= fandocUri.pod.builtOn.floor(1sec)
		this.size		= fandocUri.content.size
		this.contentType= fandocUri.fileUri.mimeType
	}

	override Uri? localUrl() {
		fandocUri.toClientUrl
	}

	override InStream? in() {
		fandocUri.content?.in
	}
}
