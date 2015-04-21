using util

** Read
** ####
** The *read* URL is used to download a specific version of a pod.
** 
** 
** Example
** -------
** Given the repository contains the pod [acmeWidgets 1.3.67]`exe:createWidgetPod(#TEXT)`
** When I query the repository with the URL [/pod/acmeWidgets/1.3.67]`exe:readFromRepo(#TEXT)` 
** then it should return the following JSON:
** 
**   exe:verifyProps(#TEXT)
**   pod.name    = acmeWidgets
**   pod.version = 1.3.67
** 
** 
** Further Details
** ===============
**  - [What if the pod doesn't exist?]`run:TestFanrReadNotFound#`
** 
class TestFanrRead : FanrFixture {

	Void createWidgetPod(Str text) {
		meta["pod.name"]	= text.split[0]
		meta["pod.version"]	= text.split[1]
		meta["pod.depends"]	= "sys 1.0"
		meta["pod.summary"]	= "Wotever"
		super.createPod
	}
	
	Void verifyProps(Str propText) {
		textProps := propText.toBuf.readProps
		fileProps := ([Str:Str]?) null
		
		zip := Zip.read(resBody.in)
		File? entry
		while ((entry = zip.readNext) != null) {
			if (entry.uri == `/meta.props`)
				fileProps = entry.readProps
		}
		zip.close
		
		textProps.each |v, k| {
			verifyEq(fileProps[k], v)
		}
	}
}
