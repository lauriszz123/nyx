local class = require("middleclass")
local AST = require("src.nyx.ast")
local Scope = require("src.nyx.scope")

local Validator = class("Validator")

Validator.visitor = {
	["AssignmentStatement"] = function(node, self)
		local target = node.target
		if target.kind == "FieldAccess" then
			local fieldType = self:checkFieldAccess(target)
			local valueType = self:getExpressionType(node.value)
			if not self:isTypeCompatible(fieldType) then
				self:addError(
					string.format("Field %s is of type %s, got: %s", target.field, fieldType, valueType),
					node
				)
			end
		else
			local var = self.scope:lookup(target.name)

			if not var then
				self:addError("Undefined variable: " .. target.name, node)
				return
			end
			local valueType = self:getExpressionType(node.value)

			if not self:isTypeCompatible(valueType) then
				self:addError(
					string.format("Cannot assign %s to variable '%s' of type %s", valueType, target.name, var.type),
					node
				)
			end
		end
	end,
}

return Validator
