local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	self:emitComment("Declaring variable " .. node.name)
	AST.visit(self, node.value, node.varType)
	self.scope:declare(node.name, node.varType)
	if not self.scope.isLocalScope then
		if node.varType == "ptr" or node.varType == "str" then
			self:emit("define_global", node.name, "u16")
		elseif node.varType == "u8" or node.varType == "s8" then
			self:emit("define_global", node.name, "u8")
		else
			error("WTF IS THIS TYPE")
		end
	end
	self:emit("")
end
