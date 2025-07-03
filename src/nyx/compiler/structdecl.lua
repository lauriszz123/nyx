---@param self Compiler
return function(self, node)
	local fields = {}
	local strfield = ""
	for _, field in ipairs(node.body) do
		strfield = strfield .. field.name .. ":" .. field.type .. ", "
		table.insert(fields, field)
	end
	strfield = strfield:sub(1, #strfield - 2)
	if #strfield ~= 0 then
		self:emit("alloc_struct", node.name, strfield)
	else
		self:emit("alloc_struct", node.name)
	end
	self.scope:declareStruct(node.name, fields)
end
