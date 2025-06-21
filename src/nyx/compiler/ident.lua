---@param self Compiler
return function(self, node)
	local var = self.scope:lookup(node.name)
	if var.isLocal then
		local index = "#" .. string.format("%d", var.index)
		-- load local variable into A
		if var.isArg then
			if var.type == "u8" or var.type == "s8" then
				self:emit("GETN", index)
			elseif var.type == "ptr" or var.type == "str" then
				self:emit("GPTN", index)
			end
		else
			if var.type == "u8" or var.type == "s8" then
				self:emit("GET", index)
			elseif var.type == "ptr" or var.type == "str" then
				self:emit("GPT", index)
			end
		end
	else
		if var.type == "u8" or var.type == "s8" then
			self:emit("LDA (v_" .. node.name .. ")")
		elseif var.type == "ptr" or var.type == "str" then
			self:emit("LDHL (v_" .. node.name .. ")")
		end
	end
end
