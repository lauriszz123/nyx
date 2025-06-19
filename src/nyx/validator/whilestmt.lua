local AST = require("src.nyx.ast")
local Types = require("src.nyx.validator.types")

---@param self Validator
return function(self, node)
	local condType = self.expression.getExpressionType(self, node.condition, "bool")
	if not Types.isTypeCompatible("bool", condType) then
		self:addError("Expected a boolean expression, got: " .. condType, node)
	end

	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end
end
