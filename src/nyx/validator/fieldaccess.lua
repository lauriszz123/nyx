local inspect = require("inspect")

---@param self Validator
return function(self, node)
	if not node.kind == "FieldAccess" then
		error("WTF? FieldAccess")
	end

	local objectName = node.object.name
	local fieldName = node.field

	local objectVar = self.scope:lookup(objectName)

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
