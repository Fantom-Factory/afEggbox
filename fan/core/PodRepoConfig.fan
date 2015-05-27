using afIocEnv
using afBeanUtils

const class PodRepoConfig {
	private static const Log			log			:= PodRepoConfig#.pod.log
	private static const TypeCoercer	typeCoercer	:= TypeCoercer()
	
	const Uri		mongoDbUrl
	const Uri?		publicUrl
	const Str?		googleAccNo
	const Str?		googleAccDomain
//	const Uri?		adminEmail
//	const Uri?		autoLoginEmail
//	const Bool		unsecured
	
	private new makeInternal(|This|in) { in(this) }
	
	This validate() {
		map := Str:Obj?[:] { ordered = true }
		
		if (googleAccNo != null)
			if (googleAccDomain == null && publicUrl == null)
				log.warn("If specifying a googleAccNo, a publicUrl or googleAccDomain should also be given.")

		map["MongoDB URL"]				= mongoDbUrl
		map["Public URL"]				= publicUrl
		map["Google Account Number"]	= googleAccNo
		map["Google Account Domain"]	= googleAccDomain
		map["."]						= ""
		map["Google Analytics Enabled"]	= googleAnalyticsEnabled
		
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
	
	static new make(IocEnv iocEnv) {
		echo("ENV: ${iocEnv.env}")
		echo("ENV: ${iocEnv.abbr}")
		// set some defaults
		configProps := ConfigProperty[
			ConfigProperty(#mongoDbUrl,			"afPodRepo.mongoDbUrl",			`mongodb://localhost:27017/podrepo`),
			ConfigProperty(#publicUrl,			"afPodRepo.publicUrl",			null),
			ConfigProperty(#googleAccNo,		"afPodRepo.googleAccNo",		null),
			ConfigProperty(#googleAccDomain,	"afPodRepo.googleAccDomain",	null),
//			ConfigProperty(#adminEmail,			"afPodRepo.adminEmail",			null),
//			ConfigProperty(#unsecured,			"afPodRepo.unsecured",	true)
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