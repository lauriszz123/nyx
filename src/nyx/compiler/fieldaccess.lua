---@param self Compiler
return function(self, node, _, getValue)
	local field = node.field
	local object = node.object
	local var = self.scope:lookup(object.name)

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
