local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	local ifend = self:newLabel()
	local ifelse

	self:emitComment("Condition")

	if node.body_false then
		ifelse = self:newLabel()

		AST.visit(self, node.condition, "u8", ifelse)
		self:emit("")
	else
		AST.visit(self, node.condition, "u8", ifend)
		self:emit("")
	end

	for _, stmt in ipairs(node.body_true) do
		AST.visit(self, stmt)
	end

	if node.body_false then
		self:emit("jump", ifend:sub(1, #ifend - 1))
		self:emit("")
		self:emitComment("Else block")
		self:emit(ifelse)
		if node.body_false.kind == "IfStatement" then
			AST.visit(self, node.body_false)
		else
			for _, stmt in ipairs(node.body_false) do
				AST.visit(self, stmt)
			end
		end
	end

	self:emit(ifend)
end
