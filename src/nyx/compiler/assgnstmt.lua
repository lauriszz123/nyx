local AST = require("src.nyx.ast")

return function(self, node)
	AST.visit(self, node.value)
	if self.scope.isLocalScope then
		local var = self.scope:fetch(node.target.name)
		self:emit("SET", "#" .. var.index)
	else
		self:emit("STA (v_" .. node.target.name .. ")")
	end
end
