local AST = require("src.nyx.ast")

return function(self, node)
	AST.visit(self, node.value, node.varType)
	if self.scope.isLocalScope then
		self.scope:declareLocal(node.name, node.varType)
		self:emit("PHA")
	else
		-- store global variable
		self.scope:declare(node.name, node.varType)
		self:emit("STA (v_" .. node.name .. ")")
	end
end
