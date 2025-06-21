local AST = require("src.nyx.ast")
local Scope = require("src.nyx.scope")

---@param self Compiler
return function(self, node)
	local variant = self.scope:declareFunction(node.name, node.params, node.retType)
	local fnName = node.name .. "_" .. variant .. ":"

	self:pushCode()
	self:emitComment("Declaring function: " .. fnName:sub(1, #fnName - 1))
	self:emit(fnName)
	self:emit("")
	self:emitComment("Setting up function header")
	self:emit("PHP #0")
	self:emit("SBP")
	self:emit("")

	-- create a new scope for the function
	---@type Scope
	self.scope = Scope(self.scope)
	self.scope.isLocalScope = true

	-- parameters
	for _, param in ipairs(node.params) do
		self.scope:declare(param.name, param.type, true)
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
