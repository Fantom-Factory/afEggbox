using afBeanUtils
using afMorphia

const class OrderedMapConverter : MapConverter {
	
	new make(|This|in) : super(in) { }
	
	override Obj:Obj? makeMap(Type mapType) {
		((Map) BeanFactory.defaultValue(mapType, true)) {
			it.ordered = true
		}
	}
}
