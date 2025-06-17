local AST = require("src.nyx.ast")

return function(self, node)
	AST.visit(self, node.value)
	if self.scope.isLocalScope then
		self.scope:declareLocal(node.name, node.varType)
		self:emit("PHA")
	else
		-- store global variable
		self.scope:declare(node.name, node.varType, self.ramAddr)
		self:emit("STA ($" .. string.format("%x", self.ramAddr) .. ")")
		self.ramAddr = self.ramAddr + 1
	end
end
