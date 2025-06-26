---@param self Compiler
return function(self, node)
	local field = node.field
	local object = node.object
	local var = self.scope:lookup(object.name)

	self:emit("load_struct", object.name)
	self:emit("load_field", field, var.type)
end
