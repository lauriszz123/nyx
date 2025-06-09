local BinaryValidator = require("src.nyx.validator.binary")

---@class ExpressionValidator
local ExpressionValidator = {}

---@param self Validator
---@param node table
---@param against string|nil
function ExpressionValidator.getExpressionType(self, node, against)
	if node.kind == "NumberLiteral" then
		if against and against == "bool" and (node.value == 0 or node.value == 1) then
			return "bool"
		end
		if node.value >= 0 and node.value <= 0xFF then
			if against then
				if against == "s8" and node.value <= 127 then
					return "s8"
				elseif against == "ptr" then
					return "ptr"
				else
					return "u8"
				end
			else
				return "u8"
			end
		elseif node.value >= -128 and node.value <= 127 then
			return "s8"
		elseif node.value >= 0 and node.value <= 0xFFFF then
			return "ptr"
		end
	elseif node.kind == "StringLiteral" then
		return "str"
	elseif node.kind == "BooleanLiteral" then
		return "bool"
	elseif node.kind == "Identifier" then
		local var = self.scope:lookup(node.name)
		if var then
			return var.type
		else
			self:addError("Undefined variable: " .. node.name, node)
			return "any"
		end
	elseif node.kind == "BinaryExpression" then
		return self.expression.checkBinaryExpression(self, node)
	elseif node.kind == "CallExpression" then
		return self.expression.checkCallExpression(self, node)
	elseif node.kind == "UnaryExpression" then
		return self.expression.checkUnaryExpression(self, node)
	elseif node.kind == "FieldAccess" then
		return self.expression.checkFieldAccess(self, node)
	else
		return "any"
	end
end

ExpressionValidator.checkBinaryExpression = require("src.nyx.validator.binary")
ExpressionValidator.checkCallExpression = require("src.nyx.validator.call")
ExpressionValidator.checkUnaryExpression = require("src.nyx.validator.unary")

return ExpressionValidator
