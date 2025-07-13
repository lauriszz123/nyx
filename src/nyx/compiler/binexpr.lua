local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node, outType, jmplbl)
	outType = outType or "u8"
	if outType == "u8" or outType == "s8" then
		AST.visit(self, node.left, outType)
		AST.visit(self, node.right, outType)
		-- apply operator
		local op = node.operator
		if op == "+" then
			self:emit("add")
		elseif op == "-" then
			self:emit("sub")
		elseif op == "*" then
			self:emit("mul")
		elseif op == "/" then
			self:emit("div")
		elseif op == "==" then
			self:emit("cmp_eq")
			self:emit("jmp_z", jmplbl:sub(1, #jmplbl - 1))
		elseif op == "!=" then
			self:emit("cmp_neq")
			self:emit("jmp_z", jmplbl:sub(1, #jmplbl - 1))
		elseif op == "<" then
			self:emit("cmp_lt")
			self:emit("jmp_z", jmplbl:sub(1, #jmplbl - 1))
		elseif op == "<=" then
			self:emit("cmp_leq")
			self:emit("jmp_z", jmplbl:sub(1, #jmplbl - 1))
		elseif op == ">" then
			self:emit("cmp_mt")
			self:emit("jmp_z", jmplbl:sub(1, #jmplbl - 1))
		elseif op == ">=" then
			self:emit("cmp_meq")
			self:emit("jmp_z", jmplbl:sub(1, #jmplbl - 1))
		else
			error("Unknown binary operator: " .. op)
		end
	elseif outType == "ptr" then
		local op = node.operator
		AST.visit(self, node.left, outType)
		AST.visit(self, node.right, "u8")
		if op == "+" then
			self:emit("add_u16")
		else
			error("POINTER OP: " .. op)
		end
	elseif outType == "u16" then
		AST.visit(self, node.left, outType)
		AST.visit(self, node.right, outType)
		-- apply operator
		local op = node.operator
		if op == "+" then
			self:emit("add_u16")
		elseif op == "-" then
			self:emit("sub_u16")
		elseif op == "*" then
			self:emit("mul_u16")
		elseif op == "/" then
			self:emit("div_u16")
		end
	else
		error("OTHER OP REACHER" .. node.operator)
	end
end
