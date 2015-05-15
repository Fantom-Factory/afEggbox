
class Docy {
	
	Void main() {
		api := ApiDocParser(File.os("C:\\Temp\\ConnectionManagerPooled.apidoc").in).parseType
		
		echo(api.toStr)
		echo(api.slots.map { it.qname })
	}
}
