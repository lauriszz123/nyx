---@param self Compiler
return function(self, node)
	local var = self.scope:lookup(node.name)
	if var.isLocal then
		local index = "#" .. string.format("%d", var.index)
		print(node.name .. " INDEX:", index)
		-- load local variable into A
		if var.isArg then
			self:emit("GETN", index)
		else
			self:emit("GET", index)
		end
	else
		if var.type == "u8" or var.type == "s8" then
			self:emit("LDA (v_" .. node.name .. ")")
		elseif var.type == "ptr" then
			self:emit("LDHL (v_" .. node.name .. ")")
		end
	end
end
