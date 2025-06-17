local AST = require("src.nyx.ast")

return function(self, node)
	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end
end
