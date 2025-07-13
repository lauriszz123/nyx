---@param self Compiler
return function(self, node)
	self:emit("const_u8 0")
end
