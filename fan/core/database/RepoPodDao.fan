using afIoc::Inject
using afMongo::MongoCur
using afMongo::MongoQ as Q
using afMorphia::Datastore

const abstract class RepoPodDao : EntityDao {
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
	abstract MongoCur 		doQuery(Str? podName)

	abstract RepoPod 		toPod(Obj doc)	
	
	new make(|This| fn) : super(fn) { }
}

internal const class RepoPodDaoImpl : RepoPodDao {

	@Inject { type=RepoPod# }
	override const Datastore datastore

	@Inject	const DirtyCash 	dirtyCache
	@Inject	const UserSession	userSession
	
	new make(|This| fn) : super(fn) { }
	
	override RepoPod? get(Str id, Bool checked := true) {
		// no cache as it's only used by testing
		datastore.findOne(checked) {
			and(allPods, eq("_id", id.lower))
		}
	}

	override RepoPod? findPod(Str name, Version? version := null) {
		dirtyCache.get(RepoPod#, _id(name, version)) |->Obj?| {
			version != null
				? get(_id(name, version), false)
				: reduceByVersion(
					Q().and(allPods, Q().eqIgnoreCase("podName", name)),
					true
				).first
		}
	}

	override RepoPod[] findPodVersions(Str name, Int? limit := null) {
		datastore.find(Q().eq("podName", name).query) {
			it->hint	= "_builtOn_"
			it->limit	= limit
		}.toList
	}
	
	override RepoPod[] findLatestPods(RepoUser? user := null) {
		query := user == null ? allPods : Q().and(allPods, Q().eq("ownerId", user._id))
		return reduceByVersion(query, true).sort(byProjName)
	}

	override RepoPod[] findOldestPods() {
		return reduceByVersion(allPods, false).sort(byProjName)
	}
	
	override RepoPod[] findLatestVersions(Int limit) {
		// cheat by using 'builtOn' index and not the actual version
		// just used by atom feed to get the latest uploads 
		return datastore.find(allPods.query) {
			it->hint	= "_builtOn_"
			it->limit	= limit
		}.toList
	}
	
	override Int countVersions(RepoUser? user := null) {
		return datastore.count {
			meh := user == null ? allPods(it) : it.and(allPods, eq("ownerId", user._id))
		}
	}

	override Int countPods(RepoUser? user := null) {
		query	 := user == null ? allPods : Q().and(allPods, Q().eq("ownerId", user._id))
		pipeline := [
			[
				"\$match" : query.query
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
		return datastore.collection.aggregate(pipeline).toList.first?.get("count") ?: 0
	}

	override MongoCur doQuery(Str? podName) {
		query := (Q) (podName == null ? allPods : Q().and(allPods, Q().eq("podName", podName)))
		return datastore.collection.find(query.query) {
			it->hint = "_builtOn_"
		}
	}
	
	override RepoPod toPod(Obj doc) {
		datastore.fromBsonDoc(doc)
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
	
	private RepoPod[] reduceByVersion(Q? query, Bool asc) {
		// https://stackoverflow.com/questions/28155546/return-all-fields-mongodb-aggregate
		// https://stackoverflow.com/questions/21053211/return-whole-document-from-aggregation
		vals	:= datastore.collection.aggregate([
			[
				"\$match"		: query.query,
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
		], null).toList
	
		pods	:= (RepoPod[]) vals.map { datastore.fromBsonDoc(it) }
		
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
	
	private Q allPods(Q? q := null) {
		q = q ?: Q()
		return userSession.isLoggedIn
			? q.or(
				Q().eq("meta.repo\\u002epublic", true), 
				Q().eq("ownerId", userSession.user._id)
			)
			: q.eq("meta.repo\\u002epublic", true)
	}
}
