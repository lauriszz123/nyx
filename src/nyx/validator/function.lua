local AST = require("src.nyx.ast")
local Scope = require("src.nyx.scope")
local Types = require("src.nyx.validator.types")

---@param self Validator
return function(self, node)
	if node.returnType and not Types.isValidType(self.scope, node.returnType) then
		self:addError("Unknown return type: " .. node.returnType, node)
	end

	for _, param in ipairs(node.params) do
		if param.type and not Types.isValidType(self.scope, param.type) then
			self:addError("Unknown parameter type: " .. param.type, node)
		end
	end

	self.scope:declareFunction(node.name, node.params, node.returnType)
	self.currentFunction = {
		returnType = node.returnType,
	}

	local oldScope = self.scope
	---@type Scope
	self.scope = Scope(self.scope)
	self.scope:setLocal()

	for _, param in ipairs(node.params) do
		self.scope:declare(param.name, param.type)
	end

	for i, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
		if stmt.kind == "ReturnStatement" and i == #node.body then
			stmt.last = true
		end
	end

	self.scope = oldScope
end
