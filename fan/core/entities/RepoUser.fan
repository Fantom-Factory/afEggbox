using afMorphia

@Entity { name = "user" }
class RepoUser {
	
	@Property { name="_id" } Str	userName
	@Property	Str					realName
	@Property	Uri					email
	@Property	Str					passwordHash

	new make(|This| in) { in(this) }
}
