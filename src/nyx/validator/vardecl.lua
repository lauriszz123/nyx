local inspect = require("inspect")

---@type NyxTypes
local Types = require("src.nyx.validator.types")

---@param self Validator
return function(self, node)
	if node.ofType then
		if not Types.isValidType(self.scope, node.ofType) then
			self:addError("Unknown type: " .. node.ofType, node)
		end
	end

	self.scope:declare(node.name, node.varType, nil, node.ofType, node.isConst)
	if node.varType and not Types.isValidType(self.scope, node.varType) then
		self:addError("Unknown type: " .. node.varType, node)
	end

	if node.isArray and node.arraySize.kind ~= "NumberLiteral" then
		self:addError("Array should be a fixed size, number or a constant", node)
	end

	if node.isConst and not node.value then
		self:addError("A const must be always initiated: " .. node.name, node)
	end

	if node.value then
		local valueType = self.expression.getExpressionType(self, node.value, node.varType)

		if valueType == "sizeof" then
			return
		end

		if not Types.isTypeCompatible(node.varType, valueType) then
			self:addError(string.format("Cannot assign %s to variable of type %s", valueType, node.varType), node)
		end
	end
end
