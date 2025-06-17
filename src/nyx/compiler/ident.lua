return function(self, node)
	local var = self.scope:lookup(node.name)
	if var.isLocal then
		-- load local variable into A
		if var.index < 0 then
			-- negative index means local variable
			self:emit("GETN #" .. string.format("%d", math.abs(var.index) + 4))
		else
			-- positive index means argument
			self:emit("GET #" .. string.format("%d", var.index))
		end
	else
		-- TODO: implement this logic for globals
		self:emit("LDA (v_" .. node.name .. ")")
	end
end
