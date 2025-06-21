local AST = require("src.nyx.ast")
-- local Scope = require("src.nyx.scope")
local Types = require("src.nyx.validator.types")

---@param self Validator
local function if_validator(self, node)
	local condType = self.expression.getExpressionType(self, node.condition, "bool")
	if not Types.isTypeCompatible("bool", condType) then
		self:addError("Expected a boolean expression, got: " .. condType, node)
	end

	for _, stmt in ipairs(node.body_true) do
		AST.visit(self, stmt)
	end

	if node.body_false then
		if node.body_false.kind == "IfStatement" then
			if_validator(self, node.body_false)
		else
			for _, stmt in ipairs(node.body_false) do
				AST.visit(self, stmt)
			end
		end
	end
end

return if_validator
