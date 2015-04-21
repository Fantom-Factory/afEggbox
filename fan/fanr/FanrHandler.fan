using afIoc
using afBedSheet
using fanr

// from fanr::WebRepoMod
const class FanrHandler {
	@Inject private const MongoRepo		repo
	@Inject private const MongoRepoAuth	auth
	@Inject private const HttpRequest	req
	@Inject private const HttpResponse	res

	** Dir to store temp files, defaults to 'Env.tempDir'
	const File tempDir := Env.cur.tempDir

	new make(|This|in) { in(this) }
	
	Text onPing() {
		authenticate
		return Text.fromJsonObj(repo.ping)
	}
	
	Text onFind(Str podName, Version? podVersion := null) {
		user := authenticate
		
		// if user can't read any pods, immediately bail
		if (!auth.allowQuery(user, null))
			sendForbiddenErr(user)
		
		spec := repo.find(podName, podVersion, false)

		if (spec == null)
			if (podVersion == null)
				sendErr(404, "Pod not found: $podName")
			else
				sendErr(404, "Pod not found: $podName $podVersion")

		// verify permissions
		if (!auth.allowQuery(user, spec))
			sendForbiddenErr(user)

		return Text.fromJsonObj(spec.meta)
    }

	Text onQuery() {
		user := authenticate

		// if user can't query any pods, immediately bail
		if (!auth.allowQuery(user, null))
			sendForbiddenErr(user)

		// query can be GET query part or POST body
		query := (req.httpMethod == "GET" ? req.url.queryStr : req.body.str) ?: sendErr(400, "Missing '?query' in URL")

		// get options
		numVersions := Int.fromStr(req.headers["Fan-NumVersions"] ?: "3", 10, false) ?: 3

		// do the query
		PodSpec[]? pods := null
		try {
			pods = repo.query(query, numVersions)
		} catch (ParseErr e) {
			sendErr(400, e.toStr)
		}

		// filter out any pods the user is not allowed to query
		pods = pods.findAll |pod| { auth.allowQuery(user, pod) }

		// return JSON response
		return Text.fromJsonObj(["pods":pods.map { it.meta }])
	}

	InStream onPod(Str podName, Version podVersion) {
		user := authenticate
		
		// if user can't read any pods, immediately bail
		if (!auth.allowRead(user, null))
			sendForbiddenErr(user)
		
		spec := repo.find(podName, podVersion, false)

		if (spec == null)
			sendErr(404, "Pod not found: $podName $podVersion")

		// verify permissions
		if (!auth.allowRead(user, spec))
			sendForbiddenErr(user)

	    res.headers["Content-Type"] = "application/zip"
	    if (spec.size != null) res.headers["Content-Length"] = spec.size.toStr

	    return repo.read(spec)
	}

	Text onPublish() {
		user := authenticate

		// if user can't publish any pods, immediately bail
		if (!auth.allowPublish(user, null))
			sendForbiddenErr(user)

		// allocate temp file
		tempName := "fanr-" + DateTime.now.toLocale("YYMMDDhhmmss") + "-" + Buf.random(4).toHex + ".pod"
		tempFile := tempDir + tempName.toUri

		try {
			// read input to temp file
			tempOut := tempFile.out
			len  := req.headers.contentLength?.toInt ?: null
			try		req.body.in.pipe(tempOut, len)
			finally	tempOut.close

			// check if user can publish this specific pod
			spec := PodSpec.load(tempFile)
			if (!auth.allowPublish(user, spec))
				sendForbiddenErr(user)

			// publish to local repo
			spec = repo.publish(tempFile, user)

			// return JSON response
			return Text.fromJsonObj(["published":spec.meta])
			
		} finally {
			try { tempFile.delete } catch { }
		}
	}
	
	
	Text onAuth() {
		username	:= req.url.queryStr ?: "*"
		user		:= auth.user(username)
		salt		:= auth.salt(user)
		secrets		:= auth.secretAlgorithms.join(",")
		signatures	:= auth.signatureAlgorithms.join(",")
		json 		:= [
			"username"				: username,
			"salt"					: salt,
			"secretAlgorithms"		: secrets,
			"signatureAlgorithms"	: signatures,
			"ts"					: now.toStr
		]
		
		if (json["salt"] == null)
			json.remove("salt")
		
		return Text.fromJsonObj(json)
	}

	private Obj? authenticate() {
		// if username header wasn't specified, then assume public request
		username := req.headers["Fanr-Username"]
		if (username == null) return null

		// check that user name is valid
		user := auth.user(username)
		if (user == null) 
			sendUnauthErr("Invalid username: $username")

		// get signature headers
		signAlgorithm	:= getRequiredHeader("Fanr-SignatureAlgorithm")
		secretAlgorithm	:= getRequiredHeader("Fanr-SecretAlgorithm").upper
		signature		:= getRequiredHeader("Fanr-Signature")
		ts				:= DateTime.fromStr(getRequiredHeader("Fanr-Ts"))

		// check timestamp is in ball-park of now to prevent replay
		// attacks, but give some fudge since clocks are never in sync
		if ((now - ts).abs > 15min)
			sendUnauthErr("Invalid timestamp window for signature: $ts != $now")

		// verify signature algorithm (we currently only support one algorithm)
		if (signAlgorithm != "HMAC-SHA1")
			sendUnauthErr("Unsupported signature algorithm: $signAlgorithm")

		// verify signature which in effect is the password verification
		s := toSignatureBody(req.httpMethod, req.urlAbs, req.headers.map)
		secret := auth.secret(user, secretAlgorithm)
		expectedSignature := s.hmac("SHA-1", secret).toBase64
		if (expectedSignature != signature)
			sendUnauthErr("Invalid password (invalid signature)")

		// at this point we have authenticated the user
		return user
	}

	private Buf toSignatureBody(Str method, Uri uri, Str:Str headers) {
		s := Buf()
		s.printLine(method.upper)
		s.printLine(uri.relToAuth.encode.lower)
		keys := headers.keys.findAll |key| {
			key = key.lower
			return key.startsWith("fanr-") && key != "fanr-signature"
		}
		keys.sort.each |key| {
			s.print(key.lower).print(":").printLine(headers[key])
		}
		return s
	}

//	private Void printPodSpecJson(OutStream out, PodSpec pod, Bool comma) {
//		out.printLine("{")
//		keys := pod.meta.keys
//		keys.moveTo("pod.name", 0)
//		keys.moveTo("pod.version", 1)
//		keys.each |k, j| {
//			v := pod.meta[k]
//			out.print(k.toCode).print(":").print(v.toCode).printLine(j+1<keys.size?",":"")
//		}
//		out.printLine(comma ? "}," : "}")
//	}

	private Str getRequiredHeader(Str key) {
		req.headers[key] ?: throw Err("Missing required header $key.toCode")
	}

	private Void sendUnauthErr(Str msg) {
		sendErr(401, msg)
    }

    private Void sendForbiddenErr(Obj? user) {
    	if (user == null) sendErr(401, "Authentication required")
    	else sendErr(403, "Not allowed")
    }

    private Str? sendErr(Int code, Str msg) {
		res.statusCode = code
		throw ReProcessErr(Text.fromJsonObj(["err":msg]))
	}

	private DateTime now() { DateTime.nowUtc(null) }
}
