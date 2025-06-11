local Types = require("src.nyx.validator.types")

---@param self Validator
local function validateStructField(self, field)
	if not Types.isValidType(self.scope, field.type) then
		self:addError("Invalid type: " .. field.type, field)
	end
end

---@param self Validator
return function(self, node)
	for _, field in ipairs(node.body) do
		validateStructField(self, field)
	end

	self.scope:declareStruct(node.name)
end
