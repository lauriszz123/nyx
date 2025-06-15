---@param self Validator
return function(self, node)
	local callee = node.callee
	local funcName = callee.name
	local func
	if callee.kind == "FieldAccess" then
		local fieldType, func_ = self.expression.checkFieldAccess(self, callee)
		if fieldType ~= "function" then
			self:addError(string.format("Field %s is not a method", callee.field), node)
		end
		func = func_
		funcName = func.name
	else
		func = self.scope:getFunction(funcName)
	end

	if not func then
		self:addError("Undefined function: " .. funcName, node)
		return "any"
	end

	if not func.isFunc then
		self:addError("Not a function: " .. funcName, node)
		return "any"
	end

	if #node.arguments ~= #func.params then
		self:addError(
			string.format("Function %s expects %d arguments, got %d", funcName, #func.params, #node.arguments),
			node
		)
	end

	for i, arg in ipairs(node.arguments) do
		if func.params[i] then
			local expectedType = func.params[i].type or "any"
			local actualType = self.expression.getExpressionType(self, arg, expectedType)

			if expectedType ~= actualType then
				self:addError(
					string.format(
						"Argument %d in function '%s': expected %s, got %s",
						i,
						funcName,
						expectedType,
						actualType
					),
					node
				)
			end
		end
	end

	return func.returnType or "any"
end
