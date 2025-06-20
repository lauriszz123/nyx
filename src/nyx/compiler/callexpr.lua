local AST = require("src.nyx.ast")

local function findFnInfo(fn, i, arg) end

---@param self Compiler
return function(self, node)
	local fname = node.callee.name .. "_" .. node.variant
	local fn = self.scope:getFunction(node.callee.name, node.variant)

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
		for i, _ in ipairs(node.arguments) do
			local argType = fn.params[i].type
			if argType == "ptr" or argType == "str" then
				self:emit("PLB")
				self:emit("PLB")
			else
				self:emit("PLB")
			end
		end
	end
end
