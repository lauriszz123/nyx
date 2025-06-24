local class = require("middleclass")

---@class Plugin
---@field initialize fun(...)

---@class PluginManager
local PluginManager = class("PluginManager")

function PluginManager:initialize()
	self.plugins = {}
end

function PluginManager:register(device)
	table.insert(self.plugins, device)
	if device.initialize then
		device:initialize()
	end
end

function PluginManager:call(fn, ...)
	local foundFn = false
	for _, device in ipairs(self.plugins) do
		if type(device[fn]) == "function" then
			device[fn](device, ...)
			foundFn = true
		end
	end

	return foundFn
end

return PluginManager
