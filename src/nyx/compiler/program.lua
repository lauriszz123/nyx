local AST = require("src.nyx.ast")

return function(self, node)
	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end
	self:emit("HLT")

	for varName, _ in pairs(self.scope.variables) do
		self:emit("v_" .. varName .. ":")
		self:emit("DB #00")
	end
end
