---@param self Compiler
return function(self, node)
	local field = node.field
	local object = node.object
	local var = self.scope:lookup(object.name)

	self:emit("LDHL", "s_" .. object.name)
	self:emit("LDA", "#" .. var.fields[field].index)
	self:emit("ADDHL")
	self:emit("")
	self:emit("LDA (HL)")
end
