using [java]com.github.sommeri.less4j.core::ThreadUnsafeLessCompiler
using [java]com.github.sommeri.less4j::LessCompiler$Configuration as Configuration
using [java]com.github.sommeri.less4j::LessCompiler$Problem as Problem
using [java]fanx.interop::Interop

class Less {
	
	Void main() {
//		inputLessFile := File.os("C:\\Projects\\Alien-Factory\\FantomFactory\\etc\\less\\website.less")
		inputLessFile := File.os("C:\\Projects\\Fantom-Factory\\PodRepo\\etc\\less\\bootstrap-3.3.4\\bootstrap.less")
		
		compiler := ThreadUnsafeLessCompiler()
		compilationResult := compiler.compile(Interop.toJava(inputLessFile), Configuration().setCompressing(true))
		
//		echo(compilationResult.getCss)
		
		Interop.toFan(compilationResult.getWarnings).each |Obj o| {
			p := (Problem) o
			echo("WARNING ${p.getLine}:${p.getCharacter} ${p.getMessage}")
		}
		echo("Done")
		
//		// print results to console
//		System.out.println(());
//		for (Problem warning : compilationResult.getWarnings()) {
//		  System.err.println(format(warning));
//		}		
	}
}
