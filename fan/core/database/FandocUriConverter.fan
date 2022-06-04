using afIoc::Inject
using afIoc::Scope
using afMorphia::BsonConv
using afMorphia::BsonConvCtx

const class FandocUriConverter : BsonConv {

	@Inject private const Scope scope
	
	new make(|This|in) { in(this) }
	
	override Obj? fromBsonVal(Obj? bsonVal, BsonConvCtx ctx) {
		if (bsonVal == null) return null
		return FandocUri.fromUri(scope, bsonVal.toStr.toUri)
	}

	override Obj? toBsonVal(Obj? fantomObj, BsonConvCtx ctx) {
		if (fantomObj == null) return null
		
		return ((FandocUri) fantomObj).toUri.toStr
	}
}
