using fanr
using afButter

** Shamelessly ripped and adapted from fanr::WebRepo
class FanrClient {
			Str?		username		// user name
			Str?		password		// plain text password
			Butter		client

	private Uri			uri				:= `/`
	private Str?		secret			// base64 string
	private Str?		secretAlgorithm	// algorithm we picked for secret
	private Duration	tsSkew	:= 0sec	// diff b/w my clock and server clock
	
	new make(|This|in) { in(this) }

	PodSpec publish(File podFile) {
		c := prepare("POST", `publish`)
		c.headers.contentType	= MimeType("application/zip")
		c.headers.contentLength	= podFile.size
//		c.headers["Expect"]		= "100-continue"
		c.body.buf = podFile.readAllBuf
		res := client.sendRequest(c)

		// parse json response
		jsonRes  := res.body.jsonMap
		jsonSpec := jsonRes["published"] ?: throw Err("Missing 'published' in JSON response")
		return PodSpec(jsonSpec, null)
	}

	private ButterRequest prepare(Str method, Uri path) {
		c := ButterRequest(uri + path)
		c.method = method
		if (username != null) sign(c)
		return c
	}

	private Void sign(ButterRequest c) {
		// first time we need to query server for algorithms and
		// user salt so we can sign our requests
		if (this.secret == null) initForSigning
		secret := Buf.fromBase64(this.secret)

		// add signing headers which are included in signature
		c.headers["Fanr-Username"]				= username
		c.headers["Fanr-SecretAlgorithm"]		= secretAlgorithm
		c.headers["Fanr-SignatureAlgorithm"]	= "HMAC-SHA1"
		c.headers["Fanr-Ts"]					= (DateTime.nowUtc + tsSkew).toStr

		// compute signature and add header
		s := toSignatureBody(c.method, c.url, c.headers.map)
		c.headers["Fanr-Signature"] = s.hmac("SHA1", secret).toBase64
	}

	internal static Buf toSignatureBody(Str method, Uri uri, Str:Str headers) {
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

	private Void initForSigning() {
		// if we don't have HMAC, then first thing we need to do is
		// ping server to get the salt for our username
		c	:= client.get(uri + `auth?$username`)
		res := c.body.jsonMap

		// get timestamp and store away delta so our requests
		// are in-sync even if our clocks are not
		ts := DateTime.fromStr(res["ts"] ?: throw Err("Response missing 'ts'"))
		tsSkew = ts - DateTime.now

		// check signature algorithms, we only support HMAC-SHA1 so
		// if server doesn't support that we have to give up now
		sigAlgorithms := res["signatureAlgorithms"] as Str ?: throw Err("Response missing 'signatureAlgorithms'")
		if (sigAlgorithms.split(',').find |a| { a.upper == "HMAC-SHA1" } == null)
			throw Err("Unsupported signature algorithms: $sigAlgorithms")

		// compute secret using secret algorithm
		secretAlgorithms := res["secretAlgorithms"] as Str ?: throw Err("Response missing 'secretAlgorithms'")
		secret = secretAlgorithms.split(',').eachWhile |a| {
			// save current normalized algorithm name
			secretAlgorithm = a = a.upper

			if (a == "PASSWORD") {
				return Buf().print(password).toBase64
			}

			if (a.upper == "SALTED-HMAC-SHA1") {
				salt := res["salt"] ?: throw Err("Response missing 'salt'")
				return Buf().print("$username:$salt").hmac("SHA-1", password.toBuf).toBase64
			}

			return null
		}
		if (secret == null) throw Err("Unsupported secret algorithms: $secretAlgorithms")
	}
}
