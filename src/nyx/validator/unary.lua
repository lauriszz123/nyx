---@param self Validator
local Types = require("src.nyx.validator.types")

---@param self Validator
return function(self, node)
	local argType = self.expression.getExpressionType(self, node.argument)
	local op = node.operator

	if op == "-" then
		if Types.isNumericType(argType) then
			if argType == "u8" then
				return "s8"
			elseif argType == "ptr" then
				self:addError("Cannot negate pointer value", node)
				return "ptr"
			else
				return argType
			end
		else
			self:addError("Unary minus requires numeric type, got " .. argType, node)
			return "s8"
		end
	elseif op == "not" then
		if argType ~= "bool" then
			self:addError("'not' operator should be used with bool type, got " .. argType, node)
		end
		return "bool"
	else
		self:addError("Unknown unary operator: " .. op, node)
		return "any"
	end
end
