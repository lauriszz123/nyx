local inspect = require("inspect")

---@param self Validator
return function(self, node)
	local object = node.object
	if object.kind == "FieldAccess" then
		local _, objectVar = self.expression.checkFieldAccess(self, object)
		if objectVar.ofType then
			objectVar = self.scope:lookup(objectVar.ofType)
		end
		if objectVar == nil then
			self:addError("Cannot access unknown object name: " .. node.object.field, node)
			return "nil", { type = "nil" }
		end

		-- Now get the field from the resolved object
		local fieldName = node.field

		if objectVar.isFunc then
			return "function", objectVar
		elseif objectVar.isStruct then
			local fieldVar = objectVar.fields[fieldName] or objectVar.methods[fieldName] or objectVar

			if fieldVar.isFunc then
				return "function", fieldVar
			else
				return fieldVar.type, fieldVar
			end
		else
			return objectVar.type, objectVar
		end
	else
		local fieldName = node.field
		local objectName = object.name

		local objectVar = self.scope:lookup(objectName)
		if not objectVar then
			print(inspect(node))
			self:addError(objectName .. " is not defined!", node)
		end

		if objectVar.ofType then
			objectVar = self.scope:lookup(objectVar.ofType)
		end

		if objectVar.isFunc then
			return "function", objectVar
		elseif objectVar.isStruct then
			local fieldVar = objectVar.fields[fieldName] or objectVar.methods[fieldName] or objectVar

			if fieldVar.isFunc then
				return "function", fieldVar
			else
				return fieldVar.type, fieldVar
			end
		else
			return objectVar.type, objectVar
		end
	end
end
