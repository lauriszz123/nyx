---@param self Compiler
return function(self, node)
	local name = self:newString(node.value)
	self:emit("LDHL", name)
end
