---@param self Compiler
return function(self, node)
	local fields = {}
	for _, field in ipairs(node.body) do
		table.insert(fields, field)
	end
	local struct = self.scope:declareStruct(node.name, fields)
	self:emit("alloc_struct", "s_" .. node.name, struct.size)
end
