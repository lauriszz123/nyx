local AST = require("src.nyx.ast")

return function(self, node)
	AST.visit(self, node.value, node.varType)
	self.scope:declare(node.name, node.varType)
	if self.scope.isLocalScope then
		if node.varType == "u8" or node.varType == "s8" then
			self:emit("PHA")
		elseif node.varType == "ptr" or node.varType == "str" then
			self:emit("PHP #1")
		end
	else
		if node.varType == "ptr" or node.varType == "str" then
			self:emit("STHL (v_" .. node.name .. ")")
		elseif node.varType == "u8" or node.varType == "s8" then
			self:emit("STA (v_" .. node.name .. ")")
		else
			error("WTF IS THIS TYPE")
		end
	end
end
