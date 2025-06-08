local class = require("middleclass")
local AST = require("src.nyx.ast")
local Scope = require("src.nyx.scope")

local Validator = class("Validator")

function Validator:getArithmeticResultType(leftType, rightType, op)
	if not (self:isNumericType(leftType) and self:isNumericType(rightType)) then
		return nil
	end

	if leftType == "ptr" or rightType == "ptr" then
		if op == "+" or op == "-" then
			if leftType == "ptr" and self:isNumericType(rightType) then
				return "ptr"
			elseif rightType == "ptr" and self:isNumericType(leftType) then
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

function Validator:checkBinaryExpression(node)
	local leftType = self:getExpressionType(node.left)
	local rightType = self:getExpressionType(node.right)
	local op = node.operator

	if op == "+" or op == "-" or op == "*" or op == "/" then
		if op == "+" and (leftType == "str" or rightType == "str") then
			if leftType == "str" and rightType == "str" then
				return "str"
			else
				self:addError(string.format("Cannot concatinate %s with %s", leftType, rightType), node)
				return "str"
			end
		end

		local resultType = self:getArithmeticResultType(leftType, rightType, op)
		if resultType then
			return resultType
		else
			self:addError(string.format("Invalid operands for '%s': %s and %s", op, leftType, rightType), node)
			return "u8"
		end
	elseif op == "==" or op == "!=" then
		if leftType ~= rightType then
			self:addWarning(string.format("Comparing different types: %s and %s", leftType, rightType), node)
		end

		return "bool"
	elseif op == "<" and op == ">" and op == "<=" and op == ">=" then
		if self:isNumericType(leftType) and self:isNumericType(rightType) then
			return "bool"
		elseif leftType == "str" and rightType == "str" then
			return "bool"
		elseif leftType == "ptr" and rightType == "ptr" then
			return "bool"
		else
			self:addError(string.format("Invalid operands for '%s': %s, %s", op, leftType, rightType), node)
			return "any"
		end
	elseif op == "and" or op == "or" then
		if leftType ~= "bool" then
			self:addWarning(string.format("Left operand of '%s' should be 'bool', got '%s'", op, rightType), node.left)
			return "any"
		end
		if rightType ~= "bool" then
			self:addWarning(string.format("Right operand of '%s' should be 'bool', got '%s'", op, leftType), node.right)
			return "any"
		end
		return "bool"
	else
		self:addError("Unknown binary operation: '" .. op .. "'", node)
		return "any"
	end
end

function Validator:checkUnaryExpression(node)
	local argType = self:getExpressionType(node.argument)
	local op = node.operator

	if op == "-" then
		if self:isNumericType(argType) then
			if argType == "u8" then
				return "s8"
			elseif argType == "ptr" then
				self:addError("Cannot negate pointer value", node)
				return "ptr"
			else
				return argType
			end
		else
			self:addError("Unary minus requires numeric type, got " .. argType, node)
			return "s8"
		end
	elseif op == "not" then
		if argType ~= "bool" then
			self:addWarning("'not' operator should be used with bool type, got " .. argType, node)
		end
		return "bool"
	else
		self:addError("Unknown unary operator: " .. op, node)
		return "any"
	end
end

function Validator:checkCallExpression(node)
	local callee = node.callee
	if callee.kind == "FieldAccess" then
		local fieldType = self:checkFieldAccess(callee)
		if fieldType ~= "function" then
			self:addError(string.format("Field %s is not a method", callee.field), node)
		end
	else
		local funcName = callee.name
		local func = self.scope:getFunction(funcName)

		if not func then
			self:addError("Undefined function: " .. funcName, node)
			return "any"
		end

		if #node.arguments ~= #func.params then
			self:addError(
				string.format("Function %s expects %d arguments, got %d", funcName, #func.params, #node.arguments),
				node
			)
		end

		for i, arg in ipairs(node.arguments) do
			if func.params[i] then
				local expectedType = func.params[i].type or "any"
				local actualType = self:getExpressionType(arg)

				if expectedType ~= actualType then
					self:addError(
						string.format("Argument %d to '%s': expected %s, got %s", i, funcName, expectedType, actualType),
						node
					)
				end
			end
		end

		return func.returnType or "any"
	end
end

function Validator:checkFieldAccess(node)
	local objectType = self:getExpressionType(node.object)
	local fieldName = node.field

	local struct = self.scope:lookup(objectType)
	return "any"
end

Validator.visitor = {
	["AssignmentStatement"] = function(node, self)
		local target = node.target
		if target.kind == "FieldAccess" then
			local fieldType = self:checkFieldAccess(target)
			local valueType = self:getExpressionType(node.value)
			if not self:isTypeCompatible(fieldType) then
				self:addError(
					string.format("Field %s is of type %s, got: %s", target.field, fieldType, valueType),
					node
				)
			end
		else
			local var = self.scope:lookup(target.name)

			if not var then
				self:addError("Undefined variable: " .. target.name, node)
				return
			end
			local valueType = self:getExpressionType(node.value)

			if not self:isTypeCompatible(valueType) then
				self:addError(
					string.format("Cannot assign %s to variable '%s' of type %s", valueType, target.name, var.type),
					node
				)
			end
		end
	end,

	["FunctionDeclaration"] = function(node, self)
		if node.returnType and not self:isValidType(node.returnType) then
			self:addError("Unknown return type: " .. node.returnType, node)
		end

		for _, param in ipairs(node.params) do
			if param.type and not self:isValidType(param.type) then
				self:addError("Unknown parameter type: " .. param.type, node)
			end
		end

		local oldScope = self.scope
		local oldCurrFunc = self.currentFunction
		self.scope = Scope(self.scope)
		self.currentFunction = node

		for _, param in ipairs(node.params) do
			self.scope:declareLocal(param.name, param.type)
		end

		local hasReturn = false
		for _, stmt in ipairs(node.body) do
			AST.visit(self, stmt)
			if stmt.kind == "ReturnStatement" then
				hasReturn = true
			end
		end

		if node.returnType and node.returnType ~= "nil" and not hasReturn then
			self:addWarning("Function '" .. node.name .. "' may not return a value", node)
		end

		self.scope = oldScope
		self.currentFunction = oldCurrFunc
	end,

	["ReturnStatement"] = function(node, self)
		if not self.currentFunction then
			self:addError("Return statement outside of function", node)
			return
		end

		local expectedType = self.currentFunction.returnType or "nil"
		local actualType = "nil"

		if node.value then
			actualType = self:getExpressionType(node.value)
		end

		if not self:isTypeCompatible(expectedType, actualType) then
			self:addError(string.format("Return type mismatch: expected %s, got %s", expectedType, actualType), node)
		end
	end,

	["ExpressionStatement"] = function(node, self)
		self:getExpressionType(node.expression)
	end,
}

return Validator
