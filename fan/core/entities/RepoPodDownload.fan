using afIoc
using afMorphia

@Entity { name = "podDownload" }
class RepoPodDownload {
	@Property 		Int			_id
	@Property const Str			podId
	@Property const Int?		userId
	@Property const DateTime	when
	@Property const Str			how

	new makeViaIoc(|This|f) { f(this) }

	new make(RepoPod pod, Str how, RepoUser? user := null) {
		this.podId		= pod._id 
		this.userId		= user?._id 
		this.when		= DateTime.now(1sec)
		this.how		= how 
	}
}
