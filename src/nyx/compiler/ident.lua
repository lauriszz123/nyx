---@param self Compiler
return function(self, node)
	local var = self.scope:lookup(node.name)
	if var.isLocal then
		local index = string.format("%d", var.index)
		-- load local variable into A
		if var.isArg then
			if var.type == "u8" or var.type == "s8" then
				self:emit("load_local_u8", -index)
			elseif var.type == "ptr" or var.type == "str" then
				self:emit("load_local_u16", -index)
			end
		else
			if var.type == "u8" or var.type == "s8" then
				self:emit("load_local_u8", index)
			elseif var.type == "ptr" or var.type == "str" then
				self:emit("load_local_u16", index)
			end
		end
	else
		if var.type == "u8" or var.type == "s8" then
			self:emit("load_global_u8", node.name)
		elseif var.type == "ptr" or var.type == "str" then
			self:emit("load_global_u16", node.name)
		end
	end
end
