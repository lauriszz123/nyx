local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	if node.target.kind == "FieldAccess" then
		local fieldAccess = node.target
		local var = self.scope:lookup(fieldAccess.object.name)

		self:emitComment("Field " .. fieldAccess.field .. " assignment in " .. fieldAccess.object.name)
		AST.visit(self, node.value, var.fields[fieldAccess.field].type)

		self:emit("PHA")
		self:emit("LDHL", "s_" .. fieldAccess.object.name)
		self:emit("LDA", "#" .. var.fields[fieldAccess.field].index)
		self:emit("ADDHL")
		self:emit("PLA")
		self:emit("")
		self:emit("STA (HL)")
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
