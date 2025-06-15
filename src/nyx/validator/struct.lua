local inspect = require("inspect")
local Types = require("src.nyx.validator.types")

---@param self Validator
local function validateStructField(self, field)
	if not Types.isValidType(self.scope, field.type) then
		self:addError("Invalid type: " .. field.type, field)
	end
end

---@param self Validator
return function(self, node)
	local fields = {}
	for _, field in ipairs(node.body) do
		validateStructField(self, field)
		fields[field.name] = {
			name = field.name,
			type = field.type,
		}
	end

	self.scope:declareStruct(node.name, fields)
end
