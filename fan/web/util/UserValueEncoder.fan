using afIoc
using afBedSheet

const class UserValueEncoder : ValueEncoder {
	
	@Inject private const RepoUserDao userDao
	
	new make(|This| in) { in(this) }
	
	override Str toClient(Obj? value) {
		if (value == null) return Str.defVal
		return ((RepoUser) value).screenName
	}

	override Obj? toValue(Str clientValue) {
		if (clientValue.isEmpty) return null
		return userDao.getByScreenName(clientValue, true)
	}
}