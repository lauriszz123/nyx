local Scope = require("src.nyx.scope")
local AST = require("src.nyx.ast")

---@param self Validator
return function(self, node)
	local struct = self.scope:getGlobalScope():lookup(node.name)
	struct.methods = {}

	self.scope = Scope(self.scope)
	self.scope:declare("self", node.name)

	for _, fn in ipairs(node.body) do
		struct.methods[fn.name] = {
			returnType = fn.returnType,
		}
		AST.visit(self, fn)
	end
	self.scope = self.scope.parent
end
