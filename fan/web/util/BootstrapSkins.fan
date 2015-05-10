using afIoc
using afBedSheet
using afFormBean

const class BootstrapTextSkin : InputSkin {
	override Str render(SkinCtx skinCtx) {
		html	:= Str.defVal
		errCss	:= skinCtx.fieldInvalid ? " has-error" : Str.defVal
		hint	:= skinCtx.input.hint ?: skinCtx.msg("field.${skinCtx.name}.hint")
		attrs	:= skinCtx.renderAttributes(["class":"form-control"])

		html	+= """<div class="form-group${errCss}">"""
		html	+= """<label for="${skinCtx.name}">${skinCtx.label}</label>"""
		html	+= """<input ${attrs} type="${skinCtx.input.type}" value="${skinCtx.value}">"""
		html	+= """</div>"""

		if (hint != null)
			// add "aria-describedby"
			html += """<span class="help-block">${hint}</span>"""				

		return html + "\n"
	}
}

const class BootstrapStaticSkin : InputSkin {
	override Str render(SkinCtx skinCtx) {
		html	:= Str.defVal
		errCss	:= skinCtx.fieldInvalid ? " has-error" : Str.defVal
		hint	:= skinCtx.input.hint ?: skinCtx.msg("field.${skinCtx.name}.hint")
		attrs	:= skinCtx.renderAttributes(["class":"form-control-static"])

		html	+= """<div class="form-group${errCss}">"""
		html	+= """<label for="${skinCtx.name}">${skinCtx.label}</label>"""
		html	+= """<p ${attrs}>${skinCtx.value.toXml}</p>"""
		html	+= """</div>"""

		if (hint != null)
			// TODO: add "aria-describedby"
			html += """<span class="help-block">${hint}</span>"""				

		return html + "\n"
	}
}

const class BootstrapErrorSkin : ErrorSkin {
	override Str render(FormBean formBean) {
		if (!formBean.hasErrors) return Str.defVal
		
		banner := formBean.messages["errors.banner"]

		html := ""
		html += """<div class="alert alert-danger" role="alert">"""
		html += banner
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