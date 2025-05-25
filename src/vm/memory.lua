local class = require "middleclass"
local DeviceManager = require "src.vm.deviceManager"

local Memory = class("Memory")

-- 64KB memory space
function Memory:initialize()
	self.ram = {}
	for i = 0, 0xFFFF do self.ram[i] = 0 end
end

function Memory:reset()
	for i = 0, 0xFFFF do self.ram[i] = 0 end
end

-- Read a byte from memory or device
function Memory:read(addr)
	addr = bit.band(addr, 0xFFFF)
	local dev_val = DeviceManager:read(addr)
	if dev_val ~= nil then return dev_val end
	return self.ram[addr]
end

-- Write a byte to memory or device
function Memory:write(addr, value)
	addr = bit.band(addr, 0xFFFF)
	if DeviceManager:write(addr, value) then return end
	self.ram[addr] = bit.band(value, 0xFF)
end

return Memory