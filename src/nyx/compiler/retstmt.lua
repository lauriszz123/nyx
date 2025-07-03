local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	if self.currentFunction then
		self.scope:generateStackCleanup(self)
		AST.visit(self, node.value)
		self:emit("set_return_value")

		if not node.last then
			local lbl = self.currentFunction.returnLabel
			self:emit("jump", lbl:sub(1, #lbl - 1))
		end
	end
end
