---@class NyxTypes
local Types = {}

local BUILT_IN_TYPES = {
	["u8"] = true,
	["s8"] = true,
	["str"] = true,
	["ptr"] = true,
	["bool"] = true,
	["nil"] = true,
}

Types.BUILT_IN = BUILT_IN_TYPES

---@param scope Scope
---@param typeName string
function Types.isValidType(scope, typeName)
	return BUILT_IN_TYPES[typeName] or scope:structExists(typeName)
end

function Types.isNumericType(typeName)
	return typeName == "u8" or typeName == "s8" or typeName == "ptr"
end

function Types.isTypeCompatible(expected, actual)
	return expected == actual
end

return Types
