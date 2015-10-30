using afIoc
using afIocConfig
using afBedSheet

const class ErrHandler {
	@Inject private const HttpRequest	httpRequest
	@Inject private const ErrEmailer	errEmailer
	
	@Config { id="afBedSheet.defaultErrResponse" }
	@Inject private const Obj			defaultErrResponse
	
	new make(|This|in) { in(this) }
	
	Obj process() {
		err := (Err) httpRequest.stash["afBedSheet.err"]
		errEmailer.emailErr(err)
		return defaultErrResponse
	}
}
