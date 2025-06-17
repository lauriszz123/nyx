local AST = require("src.nyx.ast")

return function(self, node)
	-- compile right into A, push
	AST.visit(self, node.right)
	self:emit("PHA")
	-- compile left into A
	AST.visit(self, node.left)
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
	else
		error("Unknown binary operator: " .. op)
	end
end
