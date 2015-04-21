using afIoc
using afBedSheet
using fanr

// from fanr::WebRepoMod
const class FanrHandler {
			private const Str[]			secretAlgorithms	:= ["SALTED-HMAC-SHA1"]
			private const Str[] 		signatureAlgorithms	:= ["HMAC-SHA1"]
	@Inject private const MongoRepo		repo
	@Inject private const RepoUserDao	userDao
	@Inject private const HttpRequest	req
	@Inject private const HttpResponse	res

	** Dir to store temp files, defaults to 'Env.tempDir'
	const File tempDir := Env.cur.tempDir

	new make(|This|in) { in(this) }
	
	Text onAuth() {
		username	:= req.url.queryStr ?: "*"
		user		:= userDao.get(username, false)
		salt		:= user?.userSalt
		secrets		:= secretAlgorithms.join(",")
		signatures	:= signatureAlgorithms.join(",")
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

	Text onFind(Str podName, Version? podVersion := null) {
		user := authenticate
		pod  := repo.find(user, podName, podVersion)

		if (pod == null)
			sendErr(404, "Pod not found: $podName" + (podVersion == null ? "" : " $podVersion"))

		return Text.fromJsonObj(pod.toJsonObj)
    }

	Text onPing() {
		authenticate
		return Text.fromJsonObj([
			"fanr.type"		: MongoRepo#.qname,
			"fanr.version"	: Pod.find("fanr").version.toStr
		])
	}
	
	InStream onPod(Str podName, Version podVersion) {
		user := authenticate
		pod  := repo.find(user, podName, podVersion)

		if (pod == null)
			sendErr(404, "Pod not found: $podName $podVersion")

	    res.headers.contentType 	= MimeType("application/zip")
	    res.headers.contentLength	= pod.fileSize

	    return pod.loadFile.in
	}

	Text onPublish() {
		user := authenticate

		// only registered users can publish pods, so immediately bail
		if (user == null)
			sendForbiddenErr(user)

		// allocate temp file
		tempName := "fanr-" + DateTime.now.toLocale("YYMMDDhhmmss") + "-" + Buf.random(4).toHex + ".pod"
		tempFile := tempDir + tempName.toUri

		try {
			tempOut := tempFile.out
			len  := req.headers.contentLength?.toInt ?: null
			try		req.body.in.pipe(tempOut, len)
			finally	tempOut.close

			// check if user can publish this specific pod
//			spec := PodSpec.load(tempFile)
//			if (!auth.allowPublish(user, spec))
//				sendForbiddenErr(user)

			pod := repo.publish(user, tempFile)

			return Text.fromJsonObj(["published" : pod.toJsonObj])
			
		} finally {
			try { tempFile.delete } catch { }
		}
	}

	Text onQuery() {
		user := authenticate

		// query can be GET query part or POST body
		query 		:= (req.httpMethod == "GET" ? req.url.queryStr : req.body.str) ?: sendErr(400, "Missing '?query' in URL")
		numVersions := Int.fromStr(req.headers["Fan-NumVersions"] ?: "3", 10, false) ?: 3

		// do the query
		RepoPod[]? pods := null
		try {
			pods = repo.query(user, query, numVersions)
		} catch (ParseErr e) {
			sendErr(400, e.toStr)
		}

		return Text.fromJsonObj(["pods" : pods.map { it.toJsonObj }])
	}

	private Obj? authenticate() {
		// if username header wasn't specified, then assume public request
		username := req.headers["Fanr-Username"]
		if (username == null) return null

		// check that user name is valid
		user := userDao.get(username, false)
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
		if (secretAlgorithm != "SALTED-HMAC-SHA1")
			throw Err("Unexpected secret algorithm: $secretAlgorithm")
		secret := Buf.fromBase64(user.userSecret)

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

	private Str getRequiredHeader(Str key) {
		req.headers[key] ?: sendErr(400, "Missing required header $key.toCode")
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
