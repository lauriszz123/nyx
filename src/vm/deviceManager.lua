local DeviceManager = {
	devices = {},
	map = {}
}

function DeviceManager:connect(name, dev)
	self.devices[name] = dev
	dev:connect()
	for _, addr in ipairs(dev:addresses()) do
		self.map[addr] = dev
	end
end

function DeviceManager:disconnect(name)
	local dev = self.devices[name]
	if not dev then return end
	dev:disconnect()
	for _, addr in ipairs(dev:addresses()) do
		self.map[addr] = nil
	end
	self.devices[name] = nil
end

function DeviceManager:read(addr)
	addr = bit.band(addr, 0xFFFF)
	local dev = self.map[addr]
	if dev then return dev:read(addr) end
	return nil
end

function DeviceManager:write(addr, value)
	addr = bit.band(addr, 0xFFFF)
	local dev = self.map[addr]
	if dev then dev:write(addr, value) return true end
	return false
end

return DeviceManager