local Types = require("src.nyx.validator.types")

---@param self Validator
return function(self, node)
	local target = node.target
	if target.kind == "FieldAccess" then
		local fieldType, fieldVar = self.expression.checkFieldAccess(self, target)
		local valueType = self.expression.getExpressionType(self, node.value)
		if not Types.isTypeCompatible(fieldType, valueType) then
			self:addError(string.format("Field %s is of type %s, got: %s", target.field, fieldType, valueType), node)
		end
	else
		local var = self.scope:lookup(target.name)

		if not var then
			self:addError("Undefined variable: " .. target.name, node)
			return
		end
		local valueType = self.expression.getExpressionType(self, node.value)

		if not Types.isTypeCompatible(var.type, valueType) then
			self:addError(
				string.format("Cannot assign %s to variable '%s' of type %s", valueType, target.name, var.type),
				node
			)
		end
	end
end
