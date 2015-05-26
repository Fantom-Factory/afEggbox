using concurrent
using fandoc

class LinkResolverCtx {
	RepoPod			pod
	Str?			type
	Doc?			doc
	
	new makeWithPod(RepoPod pod) { 
		this.pod = pod 
	}

	Obj? withDoc(Doc doc, |LinkResolverCtx->Obj?| func) {
		origDoc := this.doc
		try {
			this.doc = doc
			return func(this)
		} finally {
			this.doc = origDoc
		}
	}
}

const class InvalidLink {
	const FandocUri	where
	const Str		link
	const Str		msg

	new make(|This|in) { in(this) }
	
	
	static Void	setWhereLinkIsFound(FandocUri uri) {
		if (Actor.locals["afPodRepo.invalidLinks"] != null)
			Actor.locals["afPodRepo.whereLinkIsFound"] = uri
	}
	static Void	setLinkBeingResolved(Str link) {
		if (Actor.locals["afPodRepo.invalidLinks"] != null)
			Actor.locals["afPodRepo.linkBeingResolved"] = link
	}

	static Obj? invalidLink(Str msg) {
		invalidLinks?.add(InvalidLink {
			it.where	= Actor.locals["afPodRepo.whereLinkIsFound"]
			it.link		= Actor.locals["afPodRepo.linkBeingResolved"]
			it.msg		= msg
		})
		return null
	}

	static InvalidLink[] gatherInvalidLinks(|->| func) {
		Actor.locals["afPodRepo.invalidLinks"] = InvalidLink[,]
		try {
			func()
			return invalidLinks
		} finally {
			Actor.locals.remove("afPodRepo.linkBeingResolved")
			Actor.locals.remove("afPodRepo.whereLinkIsFound")
			Actor.locals.remove("afPodRepo.invalidLinks")
		}
	}
	
	static InvalidLink[]? invalidLinks() {
		Actor.locals["afPodRepo.invalidLinks"]
	}
}

const mixin InvalidLinkMsgs {
		
	static Str pathSegmentNotPods(Str pods) {
		"Path segment `/${pods}` should be `/pods`"
	}
	
	static Str invalidPodName(Str podName) {
		"Invalid pod name '${podName}'"
	}
	
	static Str tooManyPathSegments(Str[] path) {
		"Too many path segments: ${path}"
	}
	
	static Str invalidPathSegment(Str segment) {
		"Invalid path segment '${segment}'"
	}
	
	static Str invalidFantomUri() {
		"Invalid Fantom URI"
	}
	
	static Str podNotFound(Str podName, Version? podVersion) {
		"Pod ${podName}" + (podVersion ?: "") + " not found"
	}
	
	static Str invalidTypeSlotCombo() {
		"Invalid '<type>.<slot>' name"
	}
	
	static Str couldNotFindApiFiles(RepoPod pod) {
		"Pod ${pod} has no API files"
	}
	
	static Str couldNotFindType(RepoPod pod, Str typeName) {
		"Pod ${pod} does not have an API file for ${typeName}"
	}
	
	static Str couldNotFindSlot(RepoPod pod, Str typeName, Str slotName) {
		"Type ${pod}::${typeName} does not have a slot named: ${slotName}"
	}
	
	static Str couldNotFindSrcFiles(RepoPod pod) {
		"Pod ${pod} has no Src files"
	}
	
	static Str couldNotFindSrcFile(RepoPod pod, Str file) {
		"Pod ${pod} does not have an Src file for ${file}"
	}
	
	static Str couldNotFindDocFiles(RepoPod pod) {
		"Pod ${pod} has no Doc files"
	}
	
	static Str couldNotFindDocFile(RepoPod pod, Uri fileUri) {
		"Pod ${pod} does not have the Doc file `${fileUri}`"
	}

	static Str couldNotFindHeading(Str headingId, Str headings) {
		"Document does not contain the heading ID #${headingId} Available headings: ${headings}"
	}

}