using afIocEnv
using afBeanUtils
using email

const class PodRepoConfig {
	private static const Log			log			:= PodRepoConfig#.pod.log
	private static const TypeCoercer	typeCoercer	:= TypeCoercer()
	
	const Uri		mongoDbUrl
	const Uri?		publicUrl
	const Str?		googleAccNo
	const Str?		googleAccDomain
	const Str?		errorEmailsSmtpHost
	const Int?		errorEmailsSmtpPort
	const Str?		errorEmailsSmtpUsername
	const Str?		errorEmailsSmtpPassword
	const Bool		errorEmailsSmtpSsl
	const Uri?		errorEmailsSendTo
	const Uri?		autoLoginEmail
	const Uri?		adminEmail
	const Str?		contactName
	const Uri?		contactEmail
	const Bool		logDownloads
	const Bool		logActivity
	
	private new makeInternal(|This|in) { in(this) }
	
	static new make(IocEnv iocEnv) {
		configProps := ConfigProperty[
			ConfigProperty(#mongoDbUrl,					"afPodRepo.mongoDbUrl",					`mongodb://localhost:27017/podrepo`),
			ConfigProperty(#publicUrl,					"afPodRepo.publicUrl",					null),
			ConfigProperty(#googleAccNo,				"afPodRepo.googleAccNo",				null),
			ConfigProperty(#googleAccDomain,			"afPodRepo.googleAccDomain",			null),
			ConfigProperty(#errorEmailsSmtpHost,		"afPodRepo.errorEmails.smtpHost",		null),
			ConfigProperty(#errorEmailsSmtpPort,		"afPodRepo.errorEmails.smtpPort",		null),
			ConfigProperty(#errorEmailsSmtpUsername,	"afPodRepo.errorEmails.smtpUsername",	null),
			ConfigProperty(#errorEmailsSmtpPassword,	"afPodRepo.errorEmails.smtpPassword",	null),
			ConfigProperty(#errorEmailsSmtpSsl,			"afPodRepo.errorEmails.smtpSsl",		false),
			ConfigProperty(#errorEmailsSendTo,			"afPodRepo.errorEmails.sendTo",			null),
			ConfigProperty(#autoLoginEmail,				"afPodRepo.autoLoginEmail",				null),
			ConfigProperty(#adminEmail,					"afPodRepo.adminEmail",					null),
			ConfigProperty(#contactName,				"afPodRepo.contactName",				null),
			ConfigProperty(#contactEmail,				"afPodRepo.contactEmail",				null),
			ConfigProperty(#logDownloads,				"afPodRepo.logDownloads",				false),
			ConfigProperty(#logActivity,				"afPodRepo.logActivity",				false),
		]
		
		configFileName	:= (fromCmdArg(Env.cur.args, "-file") ?: fromCmdArg(Env.cur.args, "f")) ?: "config.properties"
		configFile		:= File.os(configFileName).normalize
		fileProps		:= configFile.exists ? configFile.readProps : Str:Str[:]

		// override via environment variables
		setFromEnvVars(configProps, Env.cur.vars)

		// override via properties file
		setFromPropsFile(configProps, fileProps)

		// override via command line arguments
		setFromCmdArgs(configProps, Env.cur.args)
		
		// override from Env specific props
		setFromEnvVars(configProps, Env.cur.vars, iocEnv.abbr)
		setFromPropsFile(configProps, fileProps,  iocEnv.abbr)
		setFromCmdArgs(configProps, Env.cur.args, iocEnv.abbr)
		
		// create the properties
		fieldVals := Field:Obj?[:]
		configProps.each { fieldVals[it.field] = it.value }
		itBlockFunc := Field.makeSetFunc(fieldVals)
		return PodRepoConfig(itBlockFunc).validate
	}
	
	This validate() {
		map := Str:Obj?[:] { ordered = true }
		
		if (googleAccNo != null)
			if (googleAccDomain == null && publicUrl == null)
				log.warn("If specifying a googleAccNo, a publicUrl or googleAccDomain should also be given.")

		map["MongoDB URL"]					= mongoDbUrl
		map["Public URL"]					= publicUrl
		map["Google Account Number"]		= googleAccNo
		map["Google Account Domain"]		= googleAccDomain
		map["Error Emails Smtp Host"]		= errorEmailsSmtpHost
		map["Error Emails Smtp Port"]		= errorEmailsSmtpPort
		map["Error Emails Smtp Username"]	= errorEmailsSmtpUsername
		map["Error Emails Smtp Password"]	= errorEmailsSmtpPassword
		map["Error Emails Smtp Ssl"]		= errorEmailsSmtpSsl
		map["Error Emails Send To"]			= errorEmailsSendTo
		map["Auto Login Email"]				= autoLoginEmail
		map["Admin Email"]					= adminEmail
		map["Contact Name"]					= contactName
		map["Contact Email"]				= contactEmail
		map["Log Downloads"]				= logDownloads
		map["Log Activity"]					= logActivity
		map["."]							= ""
		map["Google Analytics Enabled"]		= googleAnalyticsEnabled
		map["Error Emailing Enabled"]		= errorEmailsEnabled
		map["Auto Login Enabled"]			= autoLoginEnabled
		map["Admin Enabled"]				= adminEnabled
		map["Contact Enabled"]				= contactEnabled
		map["Log Downloads Enabled"]		= logDownloadsEnabled
		map["Log Activity Enabled"]			= logActivityEnabled
		
		msg := "\n\n"
		msg += "Pod Repo Config\n"
		msg += "===============\n"

		keySize := map.keys.reduce(0) |Int size, key->Int| { size.max(key.size) } as Int
		map.each |v, k| {
			if (v != null) {
				if (k.startsWith("."))
					msg += "".padr(keySize + 1, '-') + " : $v\n"
				else
					msg += "$k ".padr(keySize + 1, '.') + " : $v\n"
			}
		}
		log.info(msg)
		return this
	}
	
	Bool googleAnalyticsEnabled() {
		googleAccNo != null && (googleAccDomain != null || publicUrl != null)
	}

	Bool errorEmailsEnabled() {
		errorEmailsSmtpHost != null
	}

	Bool autoLoginEnabled() {
		autoLoginEmail != null
	}

	Bool adminEnabled() {
		adminEmail != null
	}

	Bool contactEnabled() {
		contactName != null && contactEmail != null
	}
	
	Bool logDownloadsEnabled() {
		logDownloads
	}

	Bool logActivityEnabled() {
		logActivity
	}

	SmtpClient errorEmailsSmtpClient() {
		// https://www.fastmail.fm/help/remote_email_access_server_names_and_ports.html
		// Server: mail.messagingengine.com
		// Port: 465
		// SSL/TLS Encryption: Enabled (but not STARTTLS)
		// Authentication: PLAIN (Our SMTP ports are for authenticated SMTP only; you'll need to make sure your software supports authenticated SMTP and also set up a username and password)
		// Username: your FastMail username/login name/email address (must include @fastmail.fm part)
		// Password: your FastMail password
		// Alternatively, if you're client supports STARTTLS only, you can use port 587 with STARTTLS enabled. 
		SmtpClient {
			host		= errorEmailsSmtpHost
			port		= errorEmailsSmtpPort ?: 25
			username	= errorEmailsSmtpUsername
			password	= errorEmailsSmtpPassword
			ssl			= errorEmailsSmtpSsl
		}
    }
	
	private static Void setFromEnvVars(ConfigProperty[] props, Str:Str envVars, Str? env := null) {
		props.each |prop| {
			if (envVars.containsKey(prop.name(env))) {
				val := envVars[prop.name(env)]
				prop.value = typeCoercer.coerce(val, prop.field.type)
			}
		}
	}

	private static Void setFromPropsFile(ConfigProperty[] props, Str:Str fileProps, Str? env := null) {
		setFromEnvVars(props, fileProps, env)
	}

	private static Void setFromCmdArgs(ConfigProperty[] props, Str[] args, Str? env := null) {
		props.each |prop| {
			val := fromCmdArg(args, prop.name(env))
			if (val != null)
				prop.value = typeCoercer.coerce(val, prop.field.type)
		}
	}
	
	private static Str? fromCmdArg(Str[] args, Str name, Str? env := null) {
		if (args.contains("-${name}")) {
			index := args.index("-${name}")
			if (args.size > (index+1))
				return args.get(index + 1)
		}
		return null
	}
}

class ConfigProperty {
	Field	field
	Str		_name
	Obj?	value
	
	new make(Field field, Str name, Obj? value) {
		this.field	= field
		this._name	= name
		this.value	= value
	}
	
	Str name(Str? env) {
		env == null ? _name : "${env}.${_name}"
	}
}