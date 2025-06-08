---@param self Validator
return function(self, node)
	if node.varType and not self:isValidType(node.varType) then
		self:addError("Unknown type: " .. node.varType, node)
	end

	if node.isArray and node.arraySize.kind ~= "NumberLiteral" then
		self:addError("Array should be a fixed size, number or a constant", node)
	end

	if node.value then
		local valueType = self:getExpressionType(node.value, node.varType)

		if not self:isTypeCompatible(node.varType, valueType) then
			if #self.warnings > 0 then
				print("=== VALIDATOR WARNINGS ===")
				for _, warn in ipairs(self.warnings) do
					print(string.format("Warning at line %d: %s", warn.line, warn.message))
				end
			end

			self:addError(string.format("Cannot assign %s to variable of type %s", valueType, node.varType), node)
		end
	end

	self.scope:declare(node.name, node.varType)
end
