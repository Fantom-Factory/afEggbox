using afIoc
using afBson
using afMongo
using afMorphia

const mixin RepoPodDao : EntityDao {
	const static Func byProjName  := |RepoPod p1, RepoPod p2 -> Int| { p1.projectName.compareIgnoreCase(p2.projectName) }
	const static Func byBuildDate := |RepoPod p1, RepoPod p2 -> Int| { p1.builtOn.compare(p2.builtOn) }

	abstract RepoPod?		get(Str id, Bool checked := true)
	abstract RepoPod? 		findPod(Str name, Version? version := null)
	abstract RepoPod[]		findPodVersions(Str name, Int? limit := null)

	abstract RepoPod[]		findLatestPods(RepoUser? user := null)		// for All Pods page & sitemap
	abstract RepoPod[]		findOldestPods()							// for Index page
	abstract RepoPod[] 		findLatestVersions(Int limit)				// for main public atom feed	
	abstract Int			countPods(RepoUser? user := null)			// for All Pods and User page
	abstract Int			countVersions(RepoUser? user := null)		// for All Pods and User page

	** used for fanr queries
	abstract RepoPod[] 		doQuery(Str? podName, |Cursor->Obj?| f)

	abstract RepoPod 		toPod(Obj doc)	
}

internal const class RepoPodDaoImpl : RepoPodDao {

	@Inject { type=RepoPod# }
	override const Datastore datastore

	@Inject
	override const IntSequences	intSeqs

	@Inject	const DirtyCash 	dirtyCache
	@Inject	const UserSession	userSession
	
	new make(|This| in) { in(this) }
	
	override RepoPod? get(Str id, Bool checked := true) {
		// no cache as it's only used by testing
		datastore.query(allPods.field("_id").eq(id.lower)).findOne(checked)
	}

	override RepoPod? findPod(Str name, Version? version := null) {
		dirtyCache.get(RepoPod#, _id(name, version)) |->Obj?| {
			version != null
				? get(_id(name, version), false)
				: reduceByVersion(allPods.field("meta.pod\\u002ename").eqIgnoreCase(name), true).first
		}
	}

	override RepoPod[] findPodVersions(Str name, Int? limit := null) {
		query := allPods.field("meta.pod\\u002ename").eq(name)
		return datastore.query(query).orderByIndex("_builtOn_").limit(limit).findAll
	}
	
	override RepoPod[] findLatestPods(RepoUser? user := null) {
		query := user == null ? allPods : allPods.field("ownerId").eq(user._id)		
		return reduceByVersion(query, true).sort(byProjName)
	}

	override RepoPod[] findOldestPods() {
		return reduceByVersion(allPods, false).sort(byProjName)
	}
	
	override RepoPod[] findLatestVersions(Int limit) {
		// cheat by using 'builtOn' index and not the actual version
		return datastore.query(allPods).orderByIndex("_builtOn_").limit(limit).findAll
	}
	
	override Int countVersions(RepoUser? user := null) {
		query := user == null ? allPods : allPods.field("ownerId").eq(user._id)
		return datastore.query(query).findCount
	}

	override Int countPods(RepoUser? user := null) {
		query	 := user == null ? allPods : allPods.field("ownerId").eq(user._id)
		pipeline := [
			[
				"\$match" : query.toMongo(datastore)
			],
			[
				"\$group" : [
					"_id" : "\$meta.pod\\u002ename"
				] 
			],
			[
				"\$group" : [
					"_id": 1, 
					"count": [
						"\$sum" : 1
					]
				]
			]
		]

		return datastore.collection.aggregateCursor(pipeline) |cur| {
			cur.next(false)?.get("count") ?: 0
		}
	}

	override RepoPod[] doQuery(Str? podName, |Cursor->Obj?| f) {
		query := (Query) (podName == null ? allPods : allPods.field("meta.pod\\u002ename").eq(podName))
		return datastore.collection.find(query.toMongo(datastore), f)
	}
	
	override RepoPod toPod(Obj doc) {
		datastore.fromMongoDoc(doc)
	}

	override RepoPod create(Obj entity) {
		datastore.insert(entity)
	}
	
	private Str:Obj? verionSortDoc(Bool asc) {
		Str:Obj?[:] { it.ordered = true }
			.add("podName", -1)
			.add("podVersion.0", asc ? -1 : 1)
			.add("podVersion.1", asc ? -1 : 1)
			.add("podVersion.2", asc ? -1 : 1)
			.add("podVersion.3", asc ? -1 : 1)
	}
	
	private RepoPod[] reduceByVersion(Query? query, Bool asc) {
		// https://stackoverflow.com/questions/28155546/return-all-fields-mongodb-aggregate
		// https://stackoverflow.com/questions/21053211/return-whole-document-from-aggregation
		vals	:= datastore.collection.aggregateCursor([
			[
				"\$match"		: query.toMongo(datastore),
			],[
				"\$sort"		: verionSortDoc(asc),
			],[
				"\$group"		: [
					"_id"			: "\$podName",
					"podName"		: ["\$first"	: "\$podName"],
					"podVersion"	: ["\$first"	: "\$podVersion"],
					"doc"			: ["\$first"	: "\$\$CURRENT"],
				],
			],[
				"\$replaceRoot"		: ["newRoot"	: "\$doc"],
			],
		]) |cur| {
			return cur.toList
		} as [Str:Obj?][]
		
		pods	:= (RepoPod[]) vals.map { datastore.fromMongoDoc(it) }
		
		// dirty cash!
		if (asc)
			pods.each { 
				dirtyCache.put(RepoPod#, it._id, it)
				// I just happen to know this is the latest!
				dirtyCache.put(RepoPod#, "${it.name}-null", it)			
			}
		return pods
	}

	private Str _id(Str name, Version? version) {
		"${name}-${version}".lower
	}
	
	private Query allPods() {
		userSession.isLoggedIn
			? Query().or([
				field("meta.repo\\u002epublic").eq(true), 
				field("ownerId").eq(userSession.user._id)
			])
			: Query().field("meta.repo\\u002epublic").eq(true)
	}
}
