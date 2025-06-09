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

function Types.getArithmeticResultType(leftType, rightType, op)
	if not (Types.isNumericType(leftType) and Types.isNumericType(rightType)) then
		return nil
	end

	if leftType == "ptr" or rightType == "ptr" then
		if op == "+" or op == "-" then
			if leftType == "ptr" and Types.isNumericType(rightType) then
				return "ptr"
			elseif rightType == "ptr" and Types.isNumericType(leftType) then
				return "ptr"
			elseif leftType == "ptr" and rightType == "ptr" and op == "-" then
				return "u8"
			end

			return nil
		end
	end

	if leftType == "s8" or rightType == "s8" then
		return "s8"
	else
		return "u8"
	end
end

return Types
