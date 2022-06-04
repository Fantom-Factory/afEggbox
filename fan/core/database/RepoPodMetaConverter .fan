using afIoc::Inject
using afMorphia::BsonConv
using afMorphia::BsonConvCtx

const class RepoPodMetaConverter : BsonConv {

	override Obj? fromBsonVal(Obj? bsonVal, BsonConvCtx ctx) {
		if (bsonVal == null) return null
		
		meta := ctx.converters.fromBsonVal(bsonVal, [Str:Str]#)
		return RepoPodMeta { it.meta = meta }
	}

	override Obj? toBsonVal(Obj? fantomObj, BsonConvCtx ctx) {
		if (fantomObj == null) return null

		meta := (RepoPodMeta) fantomObj
		return ctx.converters.toBsonVal(meta.meta)
	}
}
