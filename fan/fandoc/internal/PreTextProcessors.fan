
@NoDoc	// don't overwhelm the masses
class PreTextProcessors {
	private Str:PreTextProcessor processors
	
	new make(Str:PreTextProcessor processors) {
		this.processors = processors
	}
	
	Bool canProcess(Uri cmd) {
		processors.containsKey(cmd.scheme ?: "")
	}
	
	Void process(Uri cmd, Str preText, HtmlSkin skin) {
		processors[cmd.scheme].process(cmd, preText, skin)
	}
}