local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	self:emitComment("Varriable " .. node.target.name .. " assignment")
	AST.visit(self, node.value)
	local var = self.scope:lookup(node.target.name)
	if var.isLocal then
		self:emit("SET", "#" .. var.index)
	else
		self:emit("STA (v_" .. node.target.name .. ")")
	end
	self:emit("")
end
