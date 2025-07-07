local Types = require("src.nyx.validator.types")

---@param self Validator
return function(self, node)
	local struct = self.scope:lookup(node.struct)
	for _, field in ipairs(node.body) do
		local against = struct.fields[field.name].type
		local exprType = self.expression.getExpressionType(self, field.value, against)
		if not Types.isTypeCompatible(against, exprType) then
			self:addError(string.format("Cannot assign %s to variable of type %s", against, exprType), node)
		end
	end

	return node.struct
end
