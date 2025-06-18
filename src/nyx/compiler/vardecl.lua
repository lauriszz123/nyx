local AST = require("src.nyx.ast")

return function(self, node)
	AST.visit(self, node.value, node.varType)
	self.scope:declare(node.name, node.varType)
	if self.scope.isLocalScope then
		self:emit("PHA")
	else
		if node.varType == "ptr" then
			self:emit("STHL (v_" .. node.name .. ")")
		elseif node.varType == "u8" or node.varType == "s8" then
			self:emit("STA (v_" .. node.name .. ")")
		elseif node.varType == "str" then
			self:emit("STHL (v_" .. node.name .. ")")
		else
			error("WTF IS THIS TYPE")
		end
	end
end
