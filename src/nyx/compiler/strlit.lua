---@param self Compiler
return function(self, node)
	self:emit("load_string", node.value)
end
