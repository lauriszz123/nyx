---@param self Compiler
return function(self, node)
	local fields = {}
	for _, field in ipairs(node.body) do
		table.insert(fields, field)
	end
	self.scope:declareStruct(node.name, fields)
end
