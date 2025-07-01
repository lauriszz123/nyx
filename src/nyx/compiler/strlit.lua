---@param self Compiler
return function(self, node)
	local name = self:newString()
	self:emit("alloc_string", name, '"' .. node.value .. '"')
	self:emit("const_u16", name)
end
