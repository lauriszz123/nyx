local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	local whileStart = self:newLabel()
	local whileEnd = self:newLabel()
	self:emit(whileStart)
	AST.visit(self, node.condition, "u8", whileEnd)
	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end
	self:emit("jump", whileStart:sub(1, #whileStart - 1))
	self:emit(whileEnd)
end
