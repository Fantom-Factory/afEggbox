using afIoc
using afBedSheet
using afEfanXtra
using afPillow

@Page { disableRoutes = true }
const mixin PodApiPage : PrPage {

	@Inject			abstract RepoPodApiDao	podApiDao
	@PageContext	abstract RepoPod		pod
	@PageContext	abstract Uri			fileUri

	Str api() {
		api := podApiDao.find(pod.name, pod.version, false)?.get(fileUri)
		if (api == null)
			throw HttpStatusErr(404, "Pod API for `${fileUri}` not found")
		return api
	}
}
