using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodSrcPage : PrPage {

	@Inject			abstract RepoPodSrcDao	podSrcDao
	@PageContext	abstract RepoPod		pod
	@PageContext	abstract Uri			fileUri

	Str src() {
		src := podSrcDao.find(pod.name, pod.version, false)?.get(fileUri)
		if (src == null)
			throw HttpStatusErr(404, "Pod src for `${fileUri}` not found")
		return src
	}
}
