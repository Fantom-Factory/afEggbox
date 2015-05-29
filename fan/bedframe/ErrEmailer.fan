using afConcurrent
using afIoc
using afIocConfig
using afBedSheet
using email
using concurrent

const class ErrEmailer {
	@Inject private const Log 				log
	@Inject private const HttpRequest		req
	@Inject private const BedSheetServer	bedServer
	@Inject private const PodRepoConfig		repoConfig
	@Inject private const ErrPrinterStr		errPrinter
			private const Synchronized		lock
	
	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool				inProd
	
	new make(ActorPools actorPools, |This|in) {
		in(this) 
		this.lock = Synchronized(actorPools["afBedFrame.email"])
	}
	
	Void emailErr(Err err) {
		if (!inProd || !repoConfig.errorEmailsEnabled)	return
		
		// pass in 'req.absUri' 'cos the new thread ain't got no HTTP request!
		reqUri := bedServer.toAbsoluteUrl(req.url)

		general := "General:\n"
		general += "  Timestamp: " + DateTime.now.toLocale("DD MMM YYYY, hh:mm:ss.fff") + "\n" 
		general += "  Uri: ${reqUri}\n" 
		general += "\n" 
		email 	:= general + errPrinter.errToStr(err)
		
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
				to		= [repoConfig.errorEmailsSendTo ?: "null"]
				from	= "${podName}@${bedServer.host.host}"
				subject	= "${appName} Error :: $err.msg"
				body	= TextPart { text = emailBody }
			}
			
			repoConfig.errorEmailsSmtpClient.send(email)
			
			endTime		:= DateTime.nowTicks
			duration	:= endTime.minus(startTime).toDuration
			log.warn("Sent error email to `${email.to.join}` in ${duration.toSec} secs")
			
		} catch (Err oops) {
			log.err("Could not send error email", oops)
		}
	}
}

