local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	if node.target.kind == "FieldAccess" then
		local fieldAccess = node.target

		local var = self.scope:lookup(fieldAccess.object.name)
		if var.ofType then
			var = self.scope:lookup(var.ofType)
		end

		AST.visit(self, node.target, nil, true)
		AST.visit(self, node.value, var.fields[fieldAccess.field].type)
		self:emit("system_call", "poke_1", 2)
	else
		local var = self.scope:lookup(node.target.name)
		AST.visit(self, node.value, var.type)

		if var.isLocal then
			if var.type == "u8" then
				self:emit("set_local_u8", var.index)
			else
				error("Add this")
			end
		else
			self:emit("set_global", node.target.name)
		end
		self:emit("")
	end
end
