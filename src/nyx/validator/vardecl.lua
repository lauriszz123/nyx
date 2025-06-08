local Types = require("src.nyx.validator.types")

---@param self Validator
return function(self, node)
	if node.varType and not Types.isValidType(node.varType) then
		self:addError("Unknown type: " .. node.varType, node)
	end

	if node.isArray and node.arraySize.kind ~= "NumberLiteral" then
		self:addError("Array should be a fixed size, number or a constant", node)
	end

	if node.value then
		local valueType = self:getExpressionType(node.value, node.varType)

		if not Types.isTypeCompatible(node.varType, valueType) then
			self:addError(string.format("Cannot assign %s to variable of type %s", valueType, node.varType), node)
		end
	end

	self.scope:declare(node.name, node.varType)
end
