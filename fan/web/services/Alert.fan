using afIoc
using afBedSheet

const class Alert {	
	@Inject	private const HttpSession	httpSession
	
	Str? msg {
		get { httpSession.flash["flashMsg"] }
		set { httpSession.flash["flashMsg"] = it}
	}
	
	new make(|This| in) { in(this) }

	Bool msgExists() {
		httpSession.flashExists && httpSession.flash["flashMsg"] != null		
	}

//	Void updated(Str thing) {
//		msg = "${thing} was successfully updated"
//	}
//
//	Void created(Str thing) {
//		msg = "${thing} was successfully created"
//	}
//
//	Void deleted(Str thing) {
//		msg = "${thing} was successfully deleted"
//	}
//
//	Void cancelled(Str thing) {
//		msg = "${thing} cancelled"
//	}
//
//	Void logout(Str who) {
//		msg = "${who} has left the building."
//	}
}
