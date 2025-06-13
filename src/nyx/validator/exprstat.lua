local AST = require("src.nyx.ast")

---@param self Validator
return function(self, node)
	self.expression.getExpressionType(self, node.expression)
end
