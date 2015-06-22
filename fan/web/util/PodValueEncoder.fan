using afIoc
using afBedSheet

const class PodValueEncoder : ValueEncoder {
	
	@Inject private const RepoPodDao podDao
	
	new make(|This| in) { in(this) }
	
	override Str toClient(Obj? value) {
		if (value == null) return Str.defVal
		pod := (RepoPod) value
		return "${pod.name}-${pod.version}"	// 'cos the ID is all lower cased
	}

	override Obj? toValue(Str clientValue) {
		if (clientValue.isEmpty) return null
		return podDao.findPod(clientValue) ?: throw Err("Could not find pod: ${clientValue}")
	}
}
