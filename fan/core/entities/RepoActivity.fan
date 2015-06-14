using afIoc
using afMorphia

@Entity { name = "activity" }
class RepoActivity {
	@Property 		Int			_id
	@Property const Int?		userId
	@Property const Str?		podId
	@Property const DateTime	when
	@Property const Str			what
	@Property const Str?		detail

	new makeViaIoc(|This|f) { f(this) }

	new makeDefault(Str what, Str? detail := null) {
		this.when		= DateTime.now(1sec)
		this.what		= what 
		this.detail		= detail
	}

	new makeWithUser(RepoUser user, Str what, Str? detail := null) {
		this.userId		= user._id 
		this.when		= DateTime.now(1sec)
		this.what		= what 
		this.detail		= detail
	}

	new makeWithPod(RepoUser user, RepoPod pod, Str what, Str? detail := null) {
		this.userId		= user._id 
		this.podId		= pod._id 
		this.when		= DateTime.now(1sec)
		this.what		= what 
		this.detail		= detail
	}
}
