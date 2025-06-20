local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node, outType, jmplbl)
	outType = outType or "u8"
	if outType == "u8" or outType == "s8" then
		-- compile right into A, push
		AST.visit(self, node.right, outType)
		self:emit("PHA")
		-- compile left into A
		AST.visit(self, node.left, outType)
		-- pop right into B
		self:emit("PLB")
		-- apply operator
		local op = node.operator
		if op == "+" then
			self:emit("ADD")
		elseif op == "-" then
			self:emit("SUB")
		elseif op == "*" then
			self:emit("MUL")
		elseif op == "/" then
			self:emit("DIV")
		elseif op == "==" then
			self:emit("CMP")
			self:emit("JNZ", "(" .. jmplbl:sub(1, #jmplbl - 1) .. ")")
		elseif op == "!=" then
			self:emit("CMP")
			self:emit("JZ", "(" .. jmplbl:sub(1, #jmplbl - 1) .. ")")
		elseif op == "<" then
			local lbl = self:newLabel()

			self:emit("SUB")
			self:emit("CMP")
			self:emit("JC", "(" .. jmplbl:sub(1, #jmplbl - 1) .. ")")

			self:emit(lbl)
		elseif op == "<=" then
			local lbl = self:newLabel()

			self:emit("CMP")
			self:emit("JZ", "(" .. lbl:sub(1, #lbl - 1) .. ")")
			self:emit("SUB")
			self:emit("CMP")
			self:emit("JC", "(" .. jmplbl:sub(1, #jmplbl - 1) .. ")")

			self:emit(lbl)
		else
			error("Unknown binary operator: " .. op)
		end
	elseif outType == "ptr" then
		error("POINTER REACHED")
	end
end
