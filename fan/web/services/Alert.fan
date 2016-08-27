using afIoc
using afBedSheet

const class Alert {	
	@Inject	private const HttpSession	httpSession
	
	Str? success {
		get { httpSession.flash["flashMsg"] }
		set {
			httpSession.flashSet("flashMsg", it)
			httpSession.flashSet("flashLevel", "success")
		}
	}

	Str? error {
		get { httpSession.flash["flashMsg"] }
		set {
			httpSession.flashSet("flashMsg", it)
			httpSession.flashSet("flashLevel", "danger")
		}
	}
	
	new make(|This| in) { in(this) }

	Bool msgExists() {
		// TODO: use httpSession.flashExists when BedSheet is released 
		httpSession.exists && httpSession.containsKey("afBedSheet.flash") && httpSession.flash["flashMsg"] != null		
	}
	
	Str? message() {
		httpSession.flash["flashMsg"]
	}

	Str? level() {
		httpSession.flash["flashLevel"]
	}
}
