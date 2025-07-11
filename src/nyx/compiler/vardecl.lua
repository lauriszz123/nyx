local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	self:emitComment("Declaring variable " .. node.name)
	AST.visit(self, node.value, node.varType)
	local varType = node.varType
	self.scope:declare(node.name, varType, nil, node.ofType, node.isConst)
	if not self.scope.isLocalScope then
		if varType == "ptr" or varType == "str" then
			varType = "u16"
		end
		if node.isConst then
			self:emit("define_const", node.name, varType)
		else
			self:emit("define_global", node.name, varType)
		end
	end
	self:emit("")
end
