using afMorphia::Entity
using afMorphia::BsonProp

@Entity { name = "podDownload" }
class RepoPodDownload {
	@BsonProp 		Int			_id
	@BsonProp const Str			pod
	@BsonProp const Str			ver
	@BsonProp const Int?		userId
	@BsonProp const DateTime	when
	@BsonProp const Str			how

	new makeViaIoc(|This|f) { f(this) }

	new make(RepoPod pod, Str how, RepoUser? user := null) {
		this.pod		= pod.name.lower
		this.ver		= pod.version.toStr 
		this.userId		= user?._id 
		this.when		= DateTime.now(1sec)
		this.how		= how 
	}
}
