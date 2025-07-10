local inspect = require("inspect")
local Types = require("src.nyx.validator.types")

---@param self Validator
local function validateStructField(self, field)
	if not Types.isValidType(self.scope, field.type) then
		self:addError("Invalid type: " .. field.type, field)
	end
	if field.of then
		if not Types.isValidType(self.scope, field.of) then
			self:addError("Invalid type: " .. field.of, field)
		end
	end
end

---@param self Validator
return function(self, node)
	local fields = {}
	for _, field in ipairs(node.body) do
		fields[field.name] = {
			name = field.name,
			ofType = field.of,
			type = field.type,
		}
	end
	self.scope:declareStruct(node.name, fields)
	for _, field in ipairs(node.body) do
		validateStructField(self, field)
	end
end
