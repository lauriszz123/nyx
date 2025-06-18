local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end
	self:emit("HLT")

	for varName, var in pairs(self.scope.variables) do
		self:emit("v_" .. varName .. ":")
		if var.type == "ptr" or var.type == "str" then
			self:emit("DB #00")
			self:emit("DB #00")
		elseif var.type == "u8" or var.type == "s8" then
			self:emit("DB #00")
		end
	end

	self:generateStrings()
	self:generateFunctions()
end
