using afIoc
using afBedSheet
using afEfanXtra
using afPillow
using syntax
using web

@Page { disableRoutes = true }
const mixin PodSrcPage : PrPage {

	@Inject			abstract RepoPodSrcDao	podSrcDao
	@Inject			abstract SyntaxWriter	syntaxWriter
	@PageContext	abstract RepoPod		pod
	@PageContext	abstract Uri			fileUri

//	Str src() {
//		src := podSrcDao.find(pod.name, pod.version, false)?.get(fileUri)
//		if (src == null)
//			throw HttpStatusErr(404, "Pod src for `${fileUri}` not found")
//		
//		return syntaxWriter.writeSyntax(src, "fan", true)
//	}
	
	Str srcName() {
		idx := fileUri.name.indexr(".")
		return fileUri.name[0..<idx]
	}
}
