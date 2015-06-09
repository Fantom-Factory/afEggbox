using afIoc
using afIocEnv
using afBedSheet
using afConcurrent

const class DirtyCash {
	
	@Inject	{ type=[Str:Obj?]# }	private	const LocalMap	cache
	@Inject	{ type=[Str:Int]# }		private	const LocalMap	cacheHits
	@Inject	{ type=[Str:Int]# }		private	const LocalMap	cacheMisses
	@Inject							private	const LocalRef	cachingRef
	@Inject							private	const LocalRef	depthRef
	@Inject							private	const HttpRequest	httpReq
	@Inject							private	const IocEnv	iocEnv
	
	
	new make(|This| in) { in(this) }
	
	Bool caching {
		get { cachingRef.val ?: false }
		set { cachingRef.val = it }
	}

	Int depth {
		get { depthRef.val ?: 0 }
		set { depthRef.val = it }
	}

	Obj? cash(|->Obj?| func) {
		// allow re-enterant caching
		if (caching)
			return func()
			
		try {
			caching = true
			return func()
			
		} finally {
			caching = false
			
			if (iocEnv.isDev)
				logCash

			cache.clear
			cacheHits.clear
			cacheMisses.clear
		}
	}
	
	private Void logCash() {
		totalHits   := 0
		totalMisses := 0
		idSize := (Int) cache.keys.reduce(0) |Int size, Str key->Int| {
			size.max(key.size)
		}
		
		echo("\nDirty Cache Results for: ${httpReq.url}")
		cache.keys.each |Str k| {
			hits	:= (Int) cacheHits  .get(k, 0)
			misses	:= (Int) cacheMisses.get(k, 0)
			if (hits > 0 || misses > 0) {
				echo("  ${k.justl(idSize)} : ${hits.toStr.justr(3)} -> $misses")
				totalHits   += hits
				totalMisses += misses
			}
		}
		per := (totalHits == 0 || totalMisses == 0) ? 0f : 100 - ((totalMisses * 100).toFloat / totalHits)
		echo("  ".padr(idSize + 13, '-'))
		echo("  ".padr(idSize + 2,  ' ') + " : ${totalHits.toStr.justr(3)} -> $totalMisses = " + per.toLocale("0.00") + "% effective!")
		echo("\n")		
	}
	
	virtual Void put(Type type, Str id, Obj? val) {
		key := "$type.name->$id".lower
		cache[key] = val
	}

	virtual Obj? get(Type type, Str id, |->Obj?| func) {
		if (caching) {
			key := "$type.name->$id".lower
			if (cache.containsKey(key)) {
				cacheHits[key] = ((Int) cacheHits.get(key, 0)) + 1
			} else {
				depth 		= depth + 1
				cache[key]	= func()
				if (depth == 1)
					cacheMisses[key] = ((Int) cacheMisses.get(key, 0)) + 1
				depth = depth - 1
			}
			return cache[key]
		}
		return func()
	}	
}
