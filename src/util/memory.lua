local class = require("middleclass")

---@class Memory
local Memory = class("Memory")

-- 64KB memory space
---@param pluginManager PluginManager
function Memory:initialize(pluginManager)
	self.pluginManager = pluginManager
	self.ram = {}
	for i = 0, 0xFFFF do
		self.ram[i] = 0
	end
end

function Memory:reset()
	for i = 0, 0xFFFF do
		self.ram[i] = 0
	end
end

-- Read a byte from memory or device
function Memory:read(addr)
	addr = bit.band(addr, 0xFFFF)
	local plugin = self.pluginManager:getPlugin(addr)
	if plugin then
		return plugin:read(addr)
	end
	return self.ram[addr]
end

-- Write a byte to memory or device
function Memory:write(addr, value)
	addr = bit.band(addr, 0xFFFF)
	value = bit.band(value, 0xFF)
	local plugin = self.pluginManager:getPlugin(addr)
	if plugin then
		plugin:write(addr, value)
	end
	self.ram[addr] = bit.band(value, 0xFF)
end

return Memory
