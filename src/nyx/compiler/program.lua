local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	self:emitComment("Main program entry")
	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end
	self:emit("halt")
	self:emit("")

	self:generateStrings()
	self:generateFunctions()
end
