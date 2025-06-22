local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	if self.currentFunction then
		AST.visit(self, node.value)
		local lbl = self.currentFunction.returnLabel
		self:emit("JMP", "(" .. lbl:sub(1, #lbl - 1) .. ")")
	end
end
