local AST = require("src.nyx.ast")
local Scope = require("src.nyx.scope")

return function(self, node)
	local fnName = node.name .. ":"
	self.scope:declareFunction(node.name, node.params, node.retType)

	self:pushCode()
	self:emit(fnName)
	self:emit("PHP #0")
	self:emit("SBP")

	-- create a new scope for the function
	---@type Scope
	self.scope = Scope(self.scope)
	self.scope.isLocalScope = true

	-- parameters
	for i, param in ipairs(node.params) do
		self.scope:declare(param.name, param.varType, true)
	end

	-- compile body
	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end

	-- return (drops into caller)
	self:emit("PLP #0") -- pop base pointer
	self:emit("RET")

	-- restore scope
	self.scope = self.scope.parent

	-- restore the program code
	local fn = self:popCode()
	table.insert(self.functions, fn)
end
