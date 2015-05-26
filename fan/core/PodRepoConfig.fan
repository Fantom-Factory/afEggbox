using afIocEnv
using afBeanUtils

const class PodRepoConfig {
	
	private static const TypeCoercer	typeCoercer	:= TypeCoercer()
	
	const Uri		mongoDbUrl
	const Uri		adminEmail
	const Bool		unsecured
	
	private new makeInternal(|This|in) { in(this) }
	
	static new make(IocEnv iocEnv) {
		// set some defaults
		configProps := ConfigProperty[
			ConfigProperty(#mongoDbUrl,	"afPodRepo.mongoDbUrl",	`mongodb://localhost:27017/podrepo-dev`),
			ConfigProperty(#adminEmail,	"afPodRepo.adminEmail",	`admin@fantomPodRepo.com`),
			ConfigProperty(#unsecured,	"afPodRepo.unsecured",	true)
		]
		
		configFileName	:= (fromCmdArg(Env.cur.args, "-file") ?: fromCmdArg(Env.cur.args, "f")) ?: "config.properties"
		configFile		:= File.os(configFileName)
		fileProps		:= configFile.exists ? configFile.readProps : Str:Str[:]

		// override via environment variables
		setFromEnvVars(configProps, Env.cur.vars)

		// override via properties file
		setFromPropsFile(configProps, fileProps)

		// override via command line arguments
		setFromCmdArgs(configProps, Env.cur.args)
		
		// override from Env specific props
		setFromEnvVars(configProps, Env.cur.vars, iocEnv.env)
		setFromPropsFile(configProps, fileProps,  iocEnv.env)
		setFromCmdArgs(configProps, Env.cur.args, iocEnv.env)
		
		// create the properties
		fieldVals := Field:Obj?[:]
		configProps.each { fieldVals[it.field] = it.value }
		itBlockFunc := Field.makeSetFunc(fieldVals)
		return PodRepoConfig(itBlockFunc)
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
		setFromEnvVars(props, fileProps)
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
	
	static Void main() {
		a:=PodRepoConfig(IocEnv())
		echo(a.mongoDbUrl)
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