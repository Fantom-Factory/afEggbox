using afMorphia::BsonProp
using afMorphia::Entity

@Entity { name = "activity" }
class RepoActivity {
	@BsonProp 		Int			_id
	@BsonProp const Int?		userId
	@BsonProp const Str?		podId
	@BsonProp const DateTime	when
	@BsonProp const Str			what
	@BsonProp const Str?		detail

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
