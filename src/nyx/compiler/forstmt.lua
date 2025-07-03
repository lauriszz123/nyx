local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	local forStart = self:newLabel()
	local forEnd = self:newLabel()

	local name = node.name
	local var = self.scope:declareLocal(name, "u8")
	AST.visit(self, node.start, "u8")

	self:emit(forStart)
	AST.visit(self, {
		kind = "Identifier",
		name = name,
	})
	AST.visit(self, node.stop, "u8")

	self:emit("cmp_lt")
	self:emit("jmp_z", forEnd:sub(1, #forEnd - 1))

	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end

	AST.visit(self, {
		kind = "Identifier",
		name = name,
	})
	self:emit("const_u8 1")
	self:emit("add")
	self:emit("set_local_u8", var.index)

	self:emit("jump", forStart:sub(1, #forStart - 1))

	self:emit(forEnd)
	self.scope:deallocLocal(name)
	self:emit("pop_u8")
end
