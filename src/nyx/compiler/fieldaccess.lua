local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node, _, getValue)
	local object = node.object
	if object.kind == "FieldAccess" then
		error(node.field)
	else
		local field = node.field
		local var = self.scope:lookup(object.name)
		if var.ofType then
			var = self.scope:lookup(var.ofType)
		end

		if var.isLocal then
			self:emitComment("EMMIT A LOCAL STRUCT FETCH")
		else
			self:emit("const_u16", "s_" .. object.name)
			self:emit("const_u8", var.fields[field].index)
			self:emit("add_u16")
			if not getValue then
				self:emit("system_call", "peek_1", 1)
			end
		end
	end
end
