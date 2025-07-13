---@param self Compiler
return function(self, node)
	if node.bool then
		self:emit("const_u8 1")
	else
		self:emit("const_u8 0")
	end
end
