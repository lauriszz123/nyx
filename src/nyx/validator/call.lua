local Types = require("src.nyx.validator.types")

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

	local args = {}
	local allFuncArgs = {}

	for j, info in ipairs(func.info) do
		local funcArgs = {}

		for i, param in ipairs(info.params) do
			local arg = node.arguments[i]
			if arg then
				local actualType = self.expression.getExpressionType(self, arg, param.type)
				args[i] = actualType
				if Types.isTypeCompatible(param.type, actualType) then
					if i == #node.arguments then
						node.variant = j
						return info.returnType or "any"
					end
				end
			end
			table.insert(funcArgs, param.type)
		end

		table.insert(allFuncArgs, funcArgs)
	end

	local fstrarg = ""
	for _, fparams in ipairs(allFuncArgs) do
		fstrarg = fstrarg .. funcName .. "("
		for _, farg in ipairs(fparams) do
			fstrarg = fstrarg .. farg .. ", "
		end
		fstrarg = fstrarg:sub(1, #fstrarg - 2) .. ")\n"
	end
	local paramargs = table.concat(args, ", ")
	self:addError(
		string.format("%s(%s) did not find correct arguments for functions:\n%s", funcName, paramargs, fstrarg),
		node
	)
end
