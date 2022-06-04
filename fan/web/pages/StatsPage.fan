using afIoc::Inject
using afEfanXtra::InitRender
using afMongo::MongoColl
using afSitemap::SitemapExempt
using concurrent

const mixin StatsPage : PrPage, SitemapExempt {

	@Inject	abstract RepoUserDao	userDao
	@Inject { type=RepoPodDownload# }
			abstract MongoColl	 	collection

	@InitRender
	Void onInitPage() {
		injector.injectRequireModule("tableSort", null, ["downloads"])
	}

	RepoUser[] allUsers() {
		userDao.findAll
	}
	
	DownloadStat[] allDownloads() {
		
		pipeline := [
			[
				"\$project" : [
					"_id" : 0,
					"pod" : 1,
					"web" : [
						"\$cond" : [
							"if" : [
								"\$eq" : ["\$how", "web"]
							],
							"then" : 1,
							"else" : 0
						]
					],
					"fanr" : [
						"\$cond" : [
							"if" : [
								"\$eq" : ["\$how", "fanr"]
							],
							"then" : 1,
							"else" : 0
						]
					]
				]
			],
			[
				"\$group" : [
					"_id" : "\$pod",
					"total": [
						"\$sum" : 1
					],
					"web": [
						"\$sum" : "\$web"
					],
					"fanr": [
						"\$sum" : "\$fanr"
					]
				] 
			]
		]
		
		res := collection.aggregate(pipeline).toList
		
		return res.map |r| { 
			DownloadStat { 
				it.pod	 = r["_id"] ?: "null"; 
				it.web	 = r["web"] 
				it.fanr	 = r["fanr"] 
				it.total = r["total"] 
			} 
		}.sortr |DownloadStat p1, DownloadStat p2 ->Int| { p1.total <=> p2.total }
	}
	
}

const class DownloadStat {
	const Str	pod
	const Int	fanr
	const Int	web
	const Int	total
	new make(|This|in) { in(this) }
}
