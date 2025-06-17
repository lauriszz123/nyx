local AST = require("src.nyx.ast")

return function(self, node)
	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end

	for varName, _ in pairs(self.scope.variables) do
		self:emit("v_" .. varName .. ":")
		self:emit("DB #0x00")
	end
end
