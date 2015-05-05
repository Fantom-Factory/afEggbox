using afIoc
using afBedSheet
using afFormBean

const class BootstrapInputSkin : InputSkin {
	
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
