using afIoc
using afBedSheet
using afFormBean

const mixin BootstrapSkin : InputSkin {
	Str renderFormGroup(SkinCtx skinCtx, |Str->Str| inputStr) {
		html	:= Str.defVal
		errCss	:= skinCtx.fieldInvalid ? " has-error" : Str.defVal
		hint	:= skinCtx.input.hint ?: skinCtx.msg("field.${skinCtx.name}.hint")
		attMap	:= ["class":"form-control"]
		if (hint != null)
			attMap["aria-describedby"] = "${skinCtx.name}-helpBlock"
		attrs	:= skinCtx.renderAttributes(attMap)

		html	+= """<div class="form-group${errCss}">"""
		html	+= """<label for="${skinCtx.name}">${skinCtx.label}</label>"""
		html	+= inputStr(attrs)
		html	+= """</div>"""

		if (hint != null)
			html += """<span id="${skinCtx.name}-helpBlock" class="help-block">${hint}</span>"""				

		return html + "\n"
	}
}

const class BootstrapTextSkin : BootstrapSkin {
	override Str render(SkinCtx skinCtx) {
		renderFormGroup(skinCtx) |attrs| {
			"""<input ${attrs} type="${skinCtx.input.type}" value="${skinCtx.value}">"""
		}
	}
}

const class BootstrapTextAreaSkin : BootstrapSkin {
	override Str render(SkinCtx skinCtx) {
		renderFormGroup(skinCtx) |attrs| {
			"""<textarea ${attrs}>${skinCtx.value}</textarea>"""
		}
	}
}

const class BootstrapStaticSkin : BootstrapSkin {
	override Str render(SkinCtx skinCtx) {
		renderFormGroup(skinCtx) |attrs| {
			"""<p ${attrs}>${skinCtx.value.toXml}</p>"""
		}
	}
}

const class BootstrapCheckboxSkin : BootstrapSkin {
	override Str render(SkinCtx skinCtx) {
		checked := (skinCtx.value == "true" || skinCtx.value == "on") ? " checked" : Str.defVal
		html	:= Str.defVal
		html	+= """<div class="checkbox">"""
		html	+= """<label>"""
		html	+= """<input type="checkbox" ${skinCtx.renderAttributes}${checked}> ${skinCtx.label}"""
		html	+= """</label>"""
		html	+= """</div>"""
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