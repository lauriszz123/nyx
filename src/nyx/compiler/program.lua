local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	self:emitComment("Main program entry")
	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end
	self:emit("HLT")
	self:emit("")

	self:emitComment("Variable Memory Space")
	for varName, var in pairs(self.scope.variables) do
		if var.isStruct then
			self:emit("s_" .. varName .. ":")
			for i = 0, var.size - 1 do
				self:emit("DB #00")
			end
		elseif not var.isLocal then
			self:emit("v_" .. varName .. ":")
			if var.type == "ptr" or var.type == "str" then
				self:emit("DB #00")
				self:emit("DB #00")
			elseif var.type == "u8" or var.type == "s8" then
				self:emit("DB #00")
			end
		end
		self:emit("")
	end

	self:generateStrings()
	self:generateFunctions()
end
