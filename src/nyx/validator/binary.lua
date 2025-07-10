local Types = require("src.nyx.validator.types")

---@param self Validator
return function(self, node)
	local leftType = self.expression.getExpressionType(self, node.left)
	local rightType = self.expression.getExpressionType(self, node.right)
	local op = node.operator

	if op == "+" or op == "-" or op == "*" or op == "/" then
		if op == "+" and (leftType == "str" or rightType == "str") then
			if leftType == "str" and rightType == "str" then
				return "str"
			else
				self:addError(string.format("Cannot concatinate %s with %s", leftType, rightType), node)
				return "str"
			end
		end

		local resultType = Types.getArithmeticResultType(leftType, rightType, op)
		if resultType then
			return resultType
		else
			self:addError(string.format("Invalid operands for '%s': %s and %s", op, leftType, rightType), node)
			return "u8"
		end
	elseif op == "==" or op == "!=" then
		if rightType == "nil" then
			return "bool"
		end

		if leftType ~= rightType then
			self:addError(string.format("Comparing different types: %s and %s", leftType, rightType), node)
		end

		return "bool"
	elseif op == "<" or op == ">" or op == "<=" or op == ">=" then
		if Types.isNumericType(leftType) and Types.isNumericType(rightType) then
			return "bool"
		else
			self:addError(string.format("Invalid operands for '%s': %s, %s", op, leftType, rightType), node)
			return "any"
		end
	elseif op == "and" or op == "or" then
		if rightType ~= "bool" then
			self:addError(string.format("Left operand of '%s' should be 'bool', got '%s'", op, rightType), node.left)
			return "any"
		end
		if leftType ~= "bool" then
			self:addError(string.format("Right operand of '%s' should be 'bool', got '%s'", op, leftType), node.right)
			return "any"
		end
		return "bool"
	else
		self:addError("Unknown binary operation: '" .. op .. "'", node)
		return "any"
	end
end
