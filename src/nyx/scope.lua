local class = require("middleclass")

---@class Scope
local Scope = class("Scope")

function Scope:initialize(parent)
	self.parent = parent
	self.variables = {}
	self.isLocalScope = false
	self.functions = {}
	self.stackPtr = 1
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

function Scope:declareFunction(name, params, retType)
	if self.functions[name] then
		error("Function " .. name .. " already declared in this scope")
	end

	self.functions[name] = {
		params = params,
		returnType = retType,
	}
end

function Scope:getFunction(name)
	return self.functions[name]
end

function Scope:declareStruct(name, body)
	local global = self:getGlobalScope()
	global.variables[name] = {
		isStruct = true,
		body = body,
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

function Scope:declare(name, typ, address)
	if self.variables[name] then
		error("Variable " .. name .. " already declared in this scope")
	end

	self.variables[name] = {
		type = typ,
		position = address,
	}

	if self.isLocalScope then
		self.variables[name].isLocal = true
	else
		self.variables[name].isLocal = false
	end
end

return Scope
