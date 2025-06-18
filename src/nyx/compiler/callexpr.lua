local AST = require("src.nyx.ast")

return function(self, node, outType)
	local fname = node.callee.name
	local fn = self.scope:getFunction(fname)

	-- push args in order
	for i, arg in ipairs(node.arguments) do
		local fnParamType = fn.params[i].type
		AST.visit(self, arg, fnParamType)
		if fnParamType == "u8" or fnParamType == "s8" then
			self:emit("PHA")
		elseif fnParamType == "ptr" or fnParamType == "str" then
			self:emit("PHP #1")
		else
			print("Unsupported call argument: ", fnParamType)
		end
	end

	-- call function label
	if fn.builtin then
		fn.builtin(self)
	else
		self:emit("CALL (" .. fname .. ")")
		-- clean up args (if your VM needs manual cleanup)
		for _ = 1, #node.arguments do
			self:emit("PLB")
		end
	end
end
