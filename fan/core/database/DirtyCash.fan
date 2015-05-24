using afIoc
using afConcurrent

const class DirtyCash {
	
	@Inject	{ type=[Str:Obj?]# }	private	const LocalMap	cache
	@Inject	{ type=[Str:Int]# }		private	const LocalMap	cacheHits
	@Inject	{ type=[Str:Int]# }		private	const LocalMap	cacheMisses
	@Inject							private	const LocalRef	cachingRef
	
	new make(|This| in) { in(this) }
	
	Bool caching {
		get { cachingRef.val ?: false }
		set { cachingRef.val = it }
	}

	Obj? cash(|->Obj?| func) {
		try {
			caching = true
			return func()
			
		} finally {
			caching = false
			
			totalHits   := 0
			totalMisses := 0
			idSize := (Int) cache.keys.reduce(0) |Int size, Str key->Int| {
				size.max(key.size)
			}
			echo("\nDirty Cache Results:")
			cache.keys.each |Str k| {
				hits	:= (Int) cacheHits  .get(k, 0)
				misses	:= (Int) cacheMisses.get(k, 0)
				echo("  ${k.justl(idSize)} : ${hits.toStr.justr(3)} -> $misses")
				totalHits   += hits
				totalMisses += misses
			}
			per := 100 - ((totalMisses * 100).toFloat / totalHits)
			echo("  ".padr(idSize + 13, '-'))
			echo("  ".padr(idSize + 2,  ' ') + " : ${totalHits.toStr.justr(3)} -> $totalMisses = " + per.toLocale("0.00") + "% effective!")
			echo("\n")
			
			cache.clear
			cacheHits.clear
			cacheMisses.clear
		}
		
	}
	
	virtual Obj? get(Type type, Str id, |->Obj?| func) {
		if (caching) {
			key := "$type.name->$id"
			if (cache.containsKey(key)) {
				cacheHits[key] = ((Int) cacheHits.get(key, 0)) + 1
			} else {			
				cache[key] 		 = func()
				cacheMisses[key] = ((Int) cacheMisses.get(key, 0)) + 1
			}
			return cache[key]
		}
		return func()
	}	
}

internal class CacheHit {
	
}