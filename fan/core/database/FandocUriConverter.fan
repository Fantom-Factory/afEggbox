using afIoc
using afMorphia

const class FandocUriConverter : Converter {

	@Inject private const Registry registry
	
	new make(|This|in) { in(this) }
	
	override Obj? toFantom(Type type, Obj? mongoObj) {
		if (mongoObj == null) return null
		return FandocUri.fromUri(registry, mongoObj.toStr.toUri)
	}

	override Obj? toMongo(Obj fantomObj) {
		((FandocUri) fantomObj).toUri.toStr
	}
}
