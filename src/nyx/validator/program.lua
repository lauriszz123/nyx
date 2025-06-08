local AST = require("src.nyx.ast")

return function(self, node)
	-- TODO: Add function/struct/impl declaration
	-- before running the main visitor.

	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end
end
