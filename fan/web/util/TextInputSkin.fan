using afIoc
using afBedSheet
using afFormBean

const class TextInputSkin : DefaultInputSkin {
	
	override Str render(SkinCtx skinCtx) {
		html	:= Str.defVal
		errCss	:= skinCtx.fieldInvalid ? " has-error" : Str.defVal
		hint	:= skinCtx.input.hint ?: skinCtx.msg("field.${skinCtx.name}.hint")

		html	+= """<div class="form-group${errCss}">"""
		html	+= """<label for="${skinCtx.name}">${skinCtx.label}</label>"""
		html	+= renderElement(skinCtx)
		html	+= """</div>\n"""

		if (hint != null)
			// add "aria-describedby"
			html += """<span class="help-block">${hint}</span>"""				

		return html
	}

	override Str renderElement(SkinCtx skinCtx) {
		"""<input class="form-control" type="${skinCtx.input.type}" ${attributes(skinCtx)} value="${skinCtx.value}">"""
	}	
}
