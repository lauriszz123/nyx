local class = require("middleclass")

---@class Scope
local Scope = class("Scope")

function Scope:initialize(parent)
	self.parent = parent
	self.variables = {}
	self.isLocalScope = false
	self.functions = {}
	self.stackPtr = 0
	self.paramIndex = 5
	self.stackIndex = 0
end

function Scope:setLocal()
	self.isLocalScope = true
end

function Scope:lookup(name)
	local scope = self
	while scope do
		if scope.variables[name] then
			return scope.variables[name]
		end
		scope = scope.parent
	end
end

function Scope:getGlobalScope()
	local scope = self
	while scope ~= nil do
		if scope.parent == nil then
			return scope
		end
		scope = scope.parent
	end
end

---@param name string
---@param params table
---@param retType string
---@param builtin nil|fun(self)
function Scope:declareFunction(name, params, retType, builtin)
	local func = self.functions[name] or {
		isFunc = true,
		info = {},
	}

	table.insert(func.info, {
		params = params,
		returnType = retType,
		builtin = builtin,
	})

	self.functions[name] = func

	return #func.info
end

function Scope:getFunction(name, variant)
	local curr = self
	while curr do
		if curr.functions[name] then
			if variant then
				return curr.functions[name].info[variant]
			else
				return curr.functions[name]
			end
		end
		curr = curr.parent
	end
end

function Scope:declareStruct(name, fields)
	local global = self:getGlobalScope()
	global.variables[name] = {
		isStruct = true,
		fields = fields,
	}
end

function Scope:structExists(struct)
	local global = self:getGlobalScope()
	local var = global:lookup(struct)
	if var and var.isStruct then
		return true
	end

	return false
end

function Scope:declareLocal(name, varType)
	if self.variables[name] then
		error("Variable " .. name .. " already declared in this scope")
	end

	local var = {
		type = varType,
		isArg = false,
		isLocal = true,
	}

	if varType == "ptr" or varType == "str" then
		var.index = self.stackIndex
		self.stackIndex = self.stackIndex + 2
	else
		var.index = self.stackIndex
		self.stackIndex = self.stackIndex + 1
	end

	self.variables[name] = var

	return var
end

function Scope:deallocLocal(name)
	if not self.variables[name] then
		error("Variable " .. name .. " not in this scope")
	end

	local var = self:lookup(name)
	self.variables[name] = nil

	if var.type == "ptr" or var.type == "str" then
		self.stackIndex = self.stackIndex - 2
	else
		self.stackIndex = self.stackIndex - 1
	end

	return var
end

function Scope:declare(name, varType, isArg)
	if self.variables[name] then
		error("Variable " .. name .. " already declared in this scope")
	end
	local var = {
		type = varType,
		isArg = isArg or false,
		isLocal = false,
	}

	if self.isLocalScope then
		var.isLocal = true

		if var.isArg then
			if varType == "ptr" or varType == "str" then
				var.index = self.paramIndex + 1
				self.paramIndex = self.paramIndex + 2
			else
				var.index = self.paramIndex
				self.paramIndex = self.paramIndex + 1
			end
		else
			if varType == "ptr" or varType == "str" then
				var.index = self.stackIndex
				self.stackIndex = self.stackIndex + 2
			else
				var.index = self.stackIndex
				self.stackIndex = self.stackIndex + 1
			end
		end
	end

	self.variables[name] = var
end

---@param compiler Compiler
function Scope:generateStackCleanup(compiler)
	for _ = 0, self.stackIndex - 1 do
		compiler:emit("PLB")
	end
end

return Scope
