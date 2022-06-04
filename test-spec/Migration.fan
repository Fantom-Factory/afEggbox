using afMongo

class Migration {

	Void go() {
		echo("GOGOGO!!!")
		echo
		
		uri := `mongodb://localhost:27017/eggbox`
		client := MongoClient.makeFromUri(uri)
		
		col := client.db["pod"]
		col.find(null).each |pod| {
			vers := Version(pod["meta"]->get("pod\\u002eversion").toStr).segments.rw
			while (vers.size < 4)
				vers.add(0)
			name := pod["meta"]->get("pod\\u002ename")
			echo("$name $vers")
			col.findAndUpdate(["_id":pod["_id"]], ["\$set": ["podName":name, "podVersion":vers]])
		}
		
		echo
		echo("Done.")
	}
	
	static Void main(Str[] args) {
		Migration().go
	}
}
