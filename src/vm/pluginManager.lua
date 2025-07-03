local class = require("middleclass")

---@class Plugin
---@field initialize fun(...)

---@class PluginManager
local PluginManager = class("PluginManager")

function PluginManager:initialize()
	self.plugins = {}
	self.memorymap = {}
end

function PluginManager:register(device, startAddr, endAddr)
	if not device.read or not device.write then
		error("Device must implement read() and write() methods")
	end

	device.startAddr = startAddr
	device.endAddr = endAddr
	for addr = startAddr, endAddr do
		if self.memorymap[addr] then
			error(string.format("Memory overlap at address 0x%04X", addr))
		end
		self.memorymap[addr] = device
	end
	table.insert(self.plugins, device)
	if device.initialize then
		device:initialize()
	end
end

function PluginManager:getPlugin(addr)
	return self.memorymap[addr]
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
