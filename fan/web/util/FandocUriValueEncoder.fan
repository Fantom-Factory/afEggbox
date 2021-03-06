using afIoc
using afBedSheet

const class FandocUriValueEncoder : ValueEncoder {
	
	@Inject private const Scope	scope
	
	new make(|This| in) { in(this) }
	
	override Str toClient(Obj? value) {
		if (value == null) return Str.defVal
		return ((FandocUri) value).toUri.toStr
	}

	override Obj? toValue(Str clientValue) {
		if (clientValue.isEmpty) return null
		return FandocUri.fromUri(scope, clientValue.toUri)
	}
}
