using afIoc
using afMorphia

const class FandocUriConverter : Converter {

	@Inject private const Scope scope
	
	new make(|This|in) { in(this) }
	
	override Obj? toFantom(Type type, Obj? mongoObj) {
		if (mongoObj == null) return null
		return FandocUri.fromUri(scope, mongoObj.toStr.toUri)
	}

	override Obj? toMongo(Type fantomType, Obj? fantomObj) {
		if (fantomObj == null) return null
		
		return ((FandocUri) fantomObj).toUri.toStr
	}
}
