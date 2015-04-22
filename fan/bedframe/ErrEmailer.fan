using afConcurrent
using afIoc
using afIocConfig
using afBedSheet
using email
using concurrent

const class ErrEmailer {
	@Inject private const Log 				log
	@Inject private const Registry			reg
	@Inject private const HttpRequest		req
	@Inject private const BedSheetServer	bedServer
			private const Synchronized		lock
	
	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool				inProd
	
	new make(ActorPools actorPools, |This|in) {
		in(this) 
		this.lock = Synchronized(actorPools["afBedFrame.email"])
	}
	
	Void emailErr(Err err) {
		if (!inProd)	return
		
		// pass in 'req.absUri' 'cos the new thread ain't got no HTTP request!
		reqUri := bedServer.toAbsoluteUrl(req.url)

		general := "General:\n"
		general += "  Timestamp: " + DateTime.now.toLocale("DD MMM YYYY, hh:mm:ss.fff") + "\n" 
		general += "  Uri: ${reqUri}\n" 
		general += "\n" 
		email 	:= general + printErr(err)
		
		// Let's send those emails one at a time please!
		lock.synchronized |->| {
			doEmailErr(reqUri, email, err)
		}
	}
	
	private Void doEmailErr(Uri reqUri, Str emailBody, Err err) {
		try {
			log.info("Sending error email...")
			startTime	:= DateTime.nowTicks
	
			podName := bedServer.appPod ?: "unknown"
			appName	:= bedServer.appPod?.meta?.get("proj.name") ?: "Unknown"
			
			email := Email {
				to		= ["steve.eynon@alienfactory.co.uk"]
				from	= "${podName}@fantomfactory.org"
				subject	= "${appName} Error :: $err.msg"
				body	= TextPart { text = emailBody }
			}
			
			makeClient.send(email)
			
			endTime		:= DateTime.nowTicks
			duration	:= endTime.minus(startTime).toDuration
			log.warn("Sent error email to `${email.to.join}` in ${duration.toSec} secs")
			
		} catch (Err oops) {
			log.err("Could not send error email", oops)
		}
	}
	
	Str printErr(Err err) {
		type	:= Type.find("afBedSheet::ErrPrinterStr")
		printer	:= reg.dependencyByType(type)
		str		:= type.method("errToStr").callOn(printer, [err])
		return str
	}
	
	SmtpClient makeClient() {
		// https://www.fastmail.fm/help/remote_email_access_server_names_and_ports.html
		// Server: mail.messagingengine.com
		// Port: 465
		// SSL/TLS Encryption: Enabled (but not STARTTLS)
		// Authentication: PLAIN (Our SMTP ports are for authenticated SMTP only; you'll need to make sure your software supports authenticated SMTP and also set up a username and password)
		// Username: your FastMail username/login name/email address (must include @fastmail.fm part)
		// Password: your FastMail password
		// Alternatively, if you're client supports STARTTLS only, you can use port 587 with STARTTLS enabled. 
		SmtpClient {
			host		= "mail.messagingengine.com"
			port		= 465
			username	= "xxxxxx"
			password	= "xxxxxx"
			ssl			= true
		}
    }
}

