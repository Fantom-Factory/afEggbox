using afIoc
using afMorphia

@Entity { name = "podDownload" }
class RepoPodDownload {
	@Property 		Int			_id
	@Property const Str			pod
	@Property const Str			ver
	@Property const Int?		userId
	@Property const DateTime	when
	@Property const Str			how

	new makeViaIoc(|This|f) { f(this) }

	new make(RepoPod pod, Str how, RepoUser? user := null) {
		this.pod		= pod.name.lower
		this.ver		= pod.version.toStr 
		this.userId		= user?._id 
		this.when		= DateTime.now(1sec)
		this.how		= how 
	}
}
