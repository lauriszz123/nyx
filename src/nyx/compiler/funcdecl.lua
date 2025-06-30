local AST = require("src.nyx.ast")
local Scope = require("src.nyx.scope")

---@param self Compiler
return function(self, node)
	local retLbl = self:newLabel()
	local variant = self.scope:declareFunction(node.name, node.params, node.retType)
	self.currentFunction = {
		returnType = node.retType,
		name = node.name,
		returnLabel = retLbl,
	}
	local fnName = node.name .. "_" .. variant

	local args = ""
	for _, arg in ipairs(node.params) do
		args = args .. arg.name .. ":" .. arg.type .. ", "
	end
	args = args:sub(1, #args - 2)

	self:pushCode()
	self:emitComment("Declaring function: " .. fnName)
	self:emit("function", fnName, args)
	self:emit("")

	-- create a new scope for the function
	---@type Scope
	self.scope = Scope(self.scope)
	self.scope.isLocalScope = true

	-- parameters
	for i = #node.params, 1, -1 do
		local param = node.params[i]
		self.scope:declare(param.name, param.type, true)
	end

	-- compile body
	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end

	self:emit(retLbl)
	self.scope:generateStackCleanup(self)
	self:emit("return")

	-- restore scope
	self.scope = self.scope.parent

	-- restore the program code
	local fn = self:popCode()
	table.insert(self.functions, fn)
end
