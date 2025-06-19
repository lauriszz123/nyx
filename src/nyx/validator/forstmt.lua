local Scope = require("src.nyx.scope")
local AST = require("src.nyx.ast")
local Types = require("src.nyx.validator.types")

---@param self Validator
return function(self, node)
	self.scope = Scope(self.scope)

	self.scope:declare(node.name, "u8")
	local startType = self.expression.getExpressionType(self, node.start, "u8")
	if not Types.isTypeCompatible("u8", startType) then
		self:addError("FOR statement variable must be u8, got: " .. startType, node.start)
	end

	local stopType = self.expression.getExpressionType(self, node.stop, "u8")
	if not Types.isTypeCompatible("u8", stopType) then
		self:addError("FOR statement stop expression must be u8, got: " .. stopType, node.start)
	end

	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end

	self.scope = self.scope.parent
end
