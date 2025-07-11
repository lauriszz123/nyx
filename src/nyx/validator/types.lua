---@class NyxTypes
local Types = {}

local BUILT_IN_TYPES = {
	["u8"] = true,
	["s8"] = true,
	["u16"] = true,
	["ptr"] = true,
	["bool"] = true,
	["nil"] = true,
	["str"] = true,
}

Types.BUILT_IN = BUILT_IN_TYPES

---@param scope Scope
---@param typeName string
function Types.isValidType(scope, typeName)
	return BUILT_IN_TYPES[typeName] or scope:structExists(typeName)
end

function Types.isNumericType(typeName)
	return typeName == "u8" or typeName == "s8" or typeName == "ptr" or typeName == "u16"
end

function Types.isTypeCompatible(expected, actual)
	if actual == "nil" then
		return true
	end

	if expected == "any" then
		return true
	end

	if expected == "ptr" and actual == "u16" then
		return true
	end

	return expected == actual
end

function Types.getArithmeticResultType(leftType, rightType)
	if not (Types.isNumericType(leftType) and Types.isNumericType(rightType)) then
		return nil
	end

	if leftType == "ptr" then
		return "ptr"
	end

	if leftType == "u16" or rightType == "u16" then
		return "u16"
	end

	if leftType == "s8" or rightType == "s8" then
		return "s8"
	else
		return "u8"
	end
end

return Types
