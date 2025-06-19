local AST = require("src.nyx.ast")

return function(self, node)
	AST.visit(self, node.expression)
end
