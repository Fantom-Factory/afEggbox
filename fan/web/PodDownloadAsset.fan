using afIoc
using afBedSheet

const class PodDownloadAsset : Asset {
			 const	RepoPodFileDao	podFileDao
			 const 	Str				_id
	override const 	Bool			exists		:= true
	override const 	DateTime?		modified 
	override const 	Int?			size 
	override const 	MimeType?		contentType

	new make(RepoPodFileDao	podFileDao, RepoPod pod) {
		this.podFileDao	= podFileDao
		this._id		= pod._id
		this.modified	= pod.builtOn.floor(1sec)
		this.size		= pod.fileSize
		this.contentType= MimeType.forExt("zip")
	}

	override InStream? in() {
		podFileDao[_id].data.in
	}
}