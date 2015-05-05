using afFormBean

const class BootstrapErrorSkin : ErrorSkin {
	
	override Str render(FormBean formBean) {
		if (!formBean.hasErrors) return Str.defVal
		
		html := ""
		html += """<div class="alert alert-danger" role="alert">"""
		html += formBean.messages["errors.banner"]
		html += """<ul>"""
		formBean.errorMsgs.each {
			html += """<li>${it}</li>"""
		}
		formBean.formFields.vals.each {
			if (it.errMsg != null)
				html += """<li>${it.errMsg}</li>"""
		}
		html += """</ul>"""
		html += """</div>"""

		return html
	}
}
