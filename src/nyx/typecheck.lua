local class = require("middleclass")
local AST = require("src.nyx.ast")
local Scope = require("src.nyx.scope")

local TypeChecker = class("TypeChecker")

local BUILT_IN_TYPES = {
	['u8'] = true,
	['s8'] = true,
	['str'] = true,
	['ptr'] = true,
	['bool'] = true,
	['nil'] = true,
}

-- Initialize with a fresh scope
function TypeChecker:initialize()
	self.scope = Scope()
	self.errors = {}
	self.warnings = {}
	self.currentFunction = nil
end

function TypeChecker:addError(message, node)
	local error = {
		message = message,
		line = node.line or -1,
		column = node.column or -1,
	}
	table.insert(self.errors, error)
end

function TypeChecker:addWarning(message, node)
	local warning = {
		message = message,
		line = node.line or -1,
		column = node.column or -1,
	}
	table.insert(self.warnings, warning)
end

function TypeChecker:isValidType(typeName)
	return BUILT_IN_TYPES[typeName] or self.scope:classExists(typeName)
end

function TypeChecker:isNumericType(typeName)
	return typeName == 'u8' or typeName == 's8' or typeName == 'ptr'
end

function TypeChecker:getArithmeticResultType(leftType, rightType, op)
	if not (self:isNumericType(leftType) and self:isNumericType(rightType)) then
		return nil
	end

	if leftType == 'ptr' or rightType == 'ptr' then
		if op == '+' or op == '-' then
			if leftType == 'ptr' and self:isNumericType(rightType) then
				return 'ptr'
			elseif rightType == 'ptr' and self:isNumericType(leftType) then
				return 'ptr'
			elseif leftType == 'ptr' and rightType == 'ptr' and op == '-' then
				return 'u8'
			end

			return nil
		end
	end

	if leftType == 's8' or rightType == 's8' then
		return 's8'
	else
		return 'u8'
	end
end

function TypeChecker:getExpressionType(node, against)
	if node.kind == 'NumberLiteral' then
		if against and against == 'bool' and (node.value == 0 or node.value == 1) then
			return 'bool'
		end
		if node.value >= 0 and node.value <= 0xFF then
			if against then
				if against == 's8' and node.value <= 127 then
					return 's8'
				elseif against == 'ptr' then
					return 'ptr'
				else
					return 'u8'
				end
			else
				return 'u8'
			end
		elseif node.value >= -128 and node.value <= 127 then
			return 's8'
		elseif node.value >= 0 and node.value <= 0xFFFF then
			return 'ptr'
		end
	elseif node.kind == 'StringLiteral' then
		return 'str'
	elseif node.kind == 'BooleanLiteral' then
		return 'bool'
	elseif node.kind == 'Identifier' then
		local var = self.scope:lookup(node.name)
		if var then
			return var.type
		else
			self:addError('Undefined variable: ' .. node.name, node)
			return 'any'
		end
	elseif node.kind == 'BinaryExpression' then
		return self:checkBinaryExpression(node)
	elseif node.kind == 'CallExpression' then
		return self:checkCallExpression(node)
	elseif node.kind == 'UnaryExpression' then
		return self:checkUnaryExpression(node)
	elseif node.kind == 'FieldAccess' then
		return self:checkFieldAccess(node)
	elseif node.kind == 'NewInstance' then
		return self:checkNewInstance(node.call)
	else
		return 'any'
	end
end

function TypeChecker:checkNewInstance(node)
	if node.kind == 'CallExpression' then
		local className = node.callee.name
		local class = self.scope:lookup(className)

		if not class and class.isClass ~= nil then
			self:addError('Cannot instantiate undefined class: ' .. className, node)
			return 'any'
		end

		local constructor = class.info.methods['init']
		if constructor then
			if #node.arguments ~= #constructor.params then
				self:addError(string.format(
					'Constructor %s expects %d arguments, got %d',
					className,
					#constructor.params,
					#node.arguments
				), node)
			else
				for i, arg in ipairs(node.arguments) do
					if constructor.params[i] then
						local expectedType = constructor.params[i].type
						local actualType = self:getExpressionType(arg)

						if not self:isTypeCompatible(expectedType, actualType) then
							self:addError(string.format(
								'Constructor argument %d: expected %s, got %s',
								i, expectedType, actualType
							))
						end
					end
				end
			end

			return className
		else
			self:addError('No constructor found for class: ' .. className, node)
		end
	end
	
	return 'any'
end

function TypeChecker:checkBinaryExpression(node)
	local leftType = self:getExpressionType(node.left)
	local rightType = self:getExpressionType(node.right)
	local op = node.operator

	if op == '+' or op == '-' or op == '*' or op == '/' then
		if op == '+' and (leftType == 'str' or rightType == 'str') then
			if leftType == 'str' and rightType == 'str' then
				return 'str'
			else
				self:addError(string.format('Cannot concatinate %s with %s', leftType, rightType), node)
				return 'str'
			end
		end

		local resultType = self:getArithmeticResultType(leftType, rightType, op)
		if resultType then
			return resultType
		else
			self:addError(string.format(
				'Invalid operands for \'%s\': %s and %s',
				op,
				leftType,
				rightType
			), node)
			return 'u8'
		end
	elseif op == '==' or op == '!=' then
		if leftType ~= rightType then
			self:addWarning(string.format(
				'Comparing different types: %s and %s',
				leftType,
				rightType
			), node)
		end

		return 'bool'
	elseif op == '<' and op == '>' and op == '<=' and op == '>=' then
		if self:isNumericType(leftType) and self:isNumericType(rightType) then
			return 'bool'
		elseif leftType == 'str' and rightType == 'str' then
			return 'bool'
		elseif leftType == 'ptr' and rightType == 'ptr' then
			return 'bool'
		else
			self:addError(string.format(
				'Invalid operands for \'%s\': %s, %s',
				op,
				leftType,
				rightType
			), node)
			return 'any'
		end
	elseif op == 'and' or op == 'or' then
		if leftType ~= 'bool' then
			self:addWarning(string.format(
				'Left operand of \'%s\' should be \'bool\', got \'%s\'',
				op,
				rightType
			), node.left)
			return 'any'
		end
		if rightType ~= 'bool' then
			self:addWarning(string.format(
				'Right operand of \'%s\' should be \'bool\', got \'%s\'',
				op,
				leftType
			), node.right)
			return 'any'
		end
		return 'bool'
	else
		self:addError('Unknown binary operation: \'' .. op .. '\'', node)
		return 'any'
	end
end

function TypeChecker:checkUnaryExpression(node)
	local argType = self:getExpressionType(node.argument)
	local op = node.operator

	if op == '-' then
		if self:isNumericType(argType) then
			if argType == 'u8' then
				return 's8'
			elseif argType == 'ptr' then
				self:addError('Cannot negate pointer value', node)
				return 'ptr'
			else
				return argType
			end
		else
			self:addError('Unary minus requires numeric type, got ' .. argType, node)
			return 's8'
		end
	elseif op == 'not' then
		if argType ~= 'bool' then
			self:addWarning('\'not\' operator should be used with bool type, got ' .. argType, node)
		end
		return 'bool'
	else
		self:addError('Unknown unary operator: ' .. op, node)
		return 'any'
	end
end

function TypeChecker:checkCallExpression(node)
	local funcName = node.callee.name
	local func = self.scope:getFunction(funcName)

	if not func then
		self:addError('Undefined function: ' .. funcName, node)
		return 'any'
	end

	if #node.arguments ~= #func.params then
		self:addError(string.format(
			'Function %s expects %d arguments, got %d',
			funcName,
			#func.params,
			#node.arguments
		), node)
	end

	for i, arg in ipairs(node.arguments) do
		if func.params[i] then
			local expectedType = func.params[i].type or 'any'
			local actualType = self:getExpressionType(arg)

			if expectedType ~= actualType then
				self:addError(string.format(
					'Argument %d to \'%s\': expected %s, got %s',
					i, funcName,
					expectedType,
					actualType
				), node)
			end
		end
	end

	return func.returnType or 'any'
end

function TypeChecker:checkFieldAccess(node)
	local objectType = self:getExpressionType(node.object)
	local fieldName = node.field

	local class = self.scope:getClass(objectType)
	if not class then
		self:addError('Cannot access field of non-object type: ' .. objectType, node)
		return 'any'
	end

	for _, member in ipairs(class.members) do
		if member.kind == 'FieldDeclaration' and member.name == fieldName then
			return member.varType
		end
	end

	self:addError(string.format(
		'Class \'%s\' has no field \'%s\'',
		objectType,
		fieldName
	), node)
	return 'any'
end

function TypeChecker:isTypeCompatible(expected, actual)
	return expected == actual
end

function TypeChecker:declareClass(node)
	self.scope:declareClass(node.name, {
		typeParams = node.typeParams,
		supeclass = node.superclass,
		members = node.members,
		fields = {},
		methods = {}
	})

	local classInfo = self.scope:lookup(node.name).info
	for _, member in ipairs(node.members) do
		if member.kind == 'FieldDeclaration' then
			classInfo.fields[member.name] = {
				type = member.varType,
				hasDefaultValue = member.value ~= nil
			}
		elseif member.kind == 'FunctionDeclaration' then
			classInfo.methods[member.name] = {
				params = member.params,
				returnType = member.returnType,
			}
		else
			self:addError(string.format(
				'Unknown member %s of class %s',
				member.kind,
				node.name
			), node)
		end
	end
end

TypeChecker.visitor = {
	["Program"] = function(node, self)
		for _, stmt in ipairs(node.body) do
			if stmt.kind == 'FunctionDeclaration' then
				self.scope:declareFunction(stmt)
			end
		end

		for _, stmt in ipairs(node.body) do
			AST.visit(stmt, self.visitor, self)
		end
	end,

	["ClassDeclaration"] = function(node, self)
		if node.superclass then
			if not self:classExists(node.superclass) then
				self:addError('Undefined superclass: ' .. node.superclass, node)
			end
		end

		self:declareClass(node)
	end,

	["VariableDeclaration"] = function(node, self)
		if node.varType and not self:isValidType(node.varType) then
			self:addError('Unknown type: ' .. node.varType, node)
		end

		if node.value then
			local valueType = self:getExpressionType(node.value, node.varType)

			if not self:isTypeCompatible(node.varType, valueType) then
				self:addError(string.format('Cannot assign %s to variable of type %s', valueType, node.varType), node)
			end
		end

		self.scope:declare(node.name, node.varType)
	end,

	["AssignmentStatement"] = function(node, self)
		local targetName = node.target.name
		local var = self.scope:lookup(targetName)

		if not var then
			self:addError('Undefined variable: ' .. targetName, node)
			return
		end

		local valueType = self:getExpressionType(node.value)

		if not self:isTypeCompatible(valueType) then
			self:addError(string.format(
				'Cannot assign %s to variable \'%s\' of type %s',
				valueType,
				targetName,
				var.type
			), node)
		end
	end,

	["FunctionDeclaration"] = function(node, self)
		if node.returnType and not self:isValidType(node.returnType) then
			self:addError('Unknown return type: ' .. node.returnType, node)
		end

		for _, param in ipairs(node.params) do
			if param.type and not self:isValidType(param.type) then
				self:addError('Unknown parameter type: ' .. param.type, node)
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
			AST.visit(stmt, self.visitor, self)
			if stmt.kind == 'ReturnStatement' then
				hasReturn = true
			end
		end

		if node.returnType and node.returnType ~= 'nil' and not hasReturn then
			self:addWarning('Function \'' .. node.name .. '\' may not return a value', node)
		end

		self.scope = oldScope
		self.currentFunction = oldCurrFunc
	end,

	["ReturnStatement"] = function(node, self)
		if not self.currentFunction then
			self:addError('Return statement outside of function', node)
			return
		end

		local expectedType = self.currentFunction.returnType or 'nil'
		local actualType = 'nil'

		if node.value then
			actualType = self:getExpressionType(node.value)
		end

		if not self:isTypeCompatible(expectedType, actualType) then
			self:addError(string.format(
				'Return type mismatch: expected %s, got %s',
				expectedType,
				actualType
			), node)
		end
	end,

	["ExpressionStatement"] = function(node, self)
		self:getExpressionType(node.expression)
	end,

	["FieldDeclaration"] = function(node, self)
		if node.varType and not self:isValidType(node.varType) then
			self:addError('Unknown field type: ' .. node.varType, node)
		end
	end
}

-- Entry point: typecheck an AST
function TypeChecker:check(node)
	AST.visit(node, self.visitor, self)
	return {
		errors = self.errors,
		warnings = self.warnings,
		hasErrors = #self.errors > 0
	}
end

function TypeChecker:printResults()
	if #self.errors > 0 then
		print('=== ERRORS ===')
		for _, err in ipairs(self.errors) do
			print(string.format('Error at line %d: %s', err.line, err.message))
		end
	end
	if #self.warnings > 0 then
		print('=== WARNINGS ===')
		for _, warn in ipairs(self.warnings) do
			print(string.format('Warning at line %d: %s', warn.line, warn.message))
		end
	end

	if #self.errors == 0 and #self.warnings == 0 then
		print('No issues found!')
	end
end

return TypeChecker
