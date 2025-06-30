local AST = require("src.nyx.ast")

---@param self Compiler
return function(self, node)
	self:emitComment("Calling function " .. node.callee.name)
	local fname = node.callee.name .. "_" .. node.variant
	local fn = self.scope:getFunction(node.callee.name, node.variant)
	if not fn then
		error(fname)
	end

	-- push args in order
	for i, arg in ipairs(node.arguments) do
		AST.visit(self, arg, fn.params[i].type)
	end

	-- call function label
	if fn.builtin then
		self:emit("system_call", fname, #node.arguments)
	else
		self:emit("call", fname, #node.arguments)
	end
end
