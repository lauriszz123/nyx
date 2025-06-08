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

function Scope:isLocal(isLocal)
	self.isLocalScope = isLocal
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

function Scope:declareFunction(node)
	self.functions[node.name] = {
		params = node.params,
		returnType = node.returnType,
		body = node.body,
	}
end

function Scope:getFunction(name)
	return self.functions[name]
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

function Scope:declareClass(name, object)
	local global = self:getGlobalScope()
	global.variables[name] = {
		isClass = true,
		info = object,
	}
end

function Scope:classExists(cls)
	local global = self:getGlobalScope()
	local var = global:lookup(cls)
	if var and var.isClass then
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
		isLocal = false,
		address = address,
	}
end

function Scope:declareLocal(name, typ, index)
	if self.variables[name] then
		error("Variable " .. name .. " already declared in this scope")
	end

	self.variables[name] = {
		type = typ,
		isLocal = true,
		index = index or self.stackPtr,
	}

	if not index then
		self.stackPtr = self.stackPtr + 1
	end
end

return Scope
