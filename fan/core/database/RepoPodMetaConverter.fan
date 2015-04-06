using afIoc
using afMorphia

const class RepoPodMetaConverter : Converter {

	@Inject private const Converters converters
	
	new make(|This|in) { in(this) }
	
	override Obj? toFantom(Type type, Obj? mongoObj) {
		if (mongoObj == null) return null
		
		meta := converters.toFantom([Str:Str]#, mongoObj)
		return RepoPodMeta(meta)
	}

	override Obj? toMongo(Obj fantomObj) {
		meta := ((RepoPodMeta) fantomObj).meta
		return converters.toMongo(meta)
	}
}
