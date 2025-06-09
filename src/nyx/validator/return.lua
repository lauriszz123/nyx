local Types = require("src.nyx.validator.types")

---@param self Validator
return function(self, node)
	if not self.currentFunction then
		self:addError("Return statement outside of function", node)
		return
	end

	local expectedType = self.currentFunction.returnType or "nil"
	local actualType = "nil"

	if node.value then
		actualType = self.expression.getExpressionType(self, node.value)
	end

	if not Types.isTypeCompatible(expectedType, actualType) then
		self:addError(string.format("Return type mismatch: expected %s, got %s", expectedType, actualType), node)
	end
end
