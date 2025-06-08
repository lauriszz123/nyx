---@class ExpressionValidator
local ExpressionValidator = {}

---@param scope Scope
---@param node table
---@param against string
function ExpressionValidator.getExpressionType(scope, node, against)
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
		local var = scope:lookup(node.name)
		if var then
			return var.type
		else
			self:addError("Undefined variable: " .. node.name, node)
			return "any"
		end
	elseif node.kind == "BinaryExpression" then
		return ExpressionValidator.checkBinaryExpression(node)
	elseif node.kind == "CallExpression" then
		return ExpressionValidator.checkCallExpression(node)
	elseif node.kind == "UnaryExpression" then
		return ExpressionValidator.checkUnaryExpression(node)
	elseif node.kind == "FieldAccess" then
		return ExpressionValidator.checkFieldAccess(node)
	else
		return "any"
	end
end

return ExpressionValidator
