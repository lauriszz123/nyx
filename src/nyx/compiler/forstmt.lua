local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	local forStart = self:newLabel()
	local forBody = self:newLabel()
	local forEnd = self:newLabel()

	local name = node.name
	local var = self.scope:declareLocal(name, "u8")
	AST.visit(self, node.start, "u8")
	self:emit("store_local", name)

	self:emit(forStart)
	AST.visit(self, node.stop, "u8")
	self:emit("PHA")
	AST.visit(self, {
		kind = "Identifier",
		name = name,
	})
	self:emit("PLB")

	self:emit("CMP")
	self:emit("BCC", "(" .. forEnd:sub(1, #forEnd - 1) .. ")")

	self:emit(forBody)

	for _, stmt in ipairs(node.body) do
		AST.visit(self, stmt)
	end

	AST.visit(self, {
		kind = "Identifier",
		name = name,
	})
	self:emit("LDB #1")
	self:emit("ADD")
	self:emit("SET", "#" .. var.index)

	self:emit("JMP", "(" .. forStart:sub(1, #forStart - 1) .. ")")

	self:emit(forEnd)
	self.scope:deallocLocal(name)
	self:emit("PLB")
end
