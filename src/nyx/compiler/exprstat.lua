local AST = require("src.nyx.ast")

return function(self, node, outType)
	AST.visit(self, node.expression, outType)
end
