
const mixin Utils {
	
	static Str fromDisplayName(Str humanName) {
		Str.fromChars(humanName.fromDisplayName.chars.findAll { it.isAlphaNum })
	}

}
