local class = require("middleclass")
local inspect = require("inspect")

local Memory = require("src.vm.memory")
local CPU = require("src.vm.cpu")
local DeviceManager = require("src.vm.deviceManager")

---@class VM
local VM = class("VM")

function VM:initialize()
	self.memory = Memory()
	---@type CPU
	self.cpu = CPU(self.memory)
	self.cycles = 0
	self.running = false
end

function VM:reset(bytecode, offset)
	offset = offset or 0
	self.running = true
	self.cpu:reset()
	for i = 1, #bytecode do
		self.memory:write(offset + (i - 1), bytecode[i])
		print(string.format("0x%04X: %02X", offset + (i - 1), bytecode[i]))
	end
	self.memory:write(0xFFFC, 0x00) -- Reset vector low byte
	self.memory:write(0xFFFF, 0x00) -- Reset vector high byte

	print("VM reset at offset: " .. string.format("0x%04X", offset))
	print("Bytecode loaded: " .. #bytecode .. " bytes")
	print("Reset vector: " .. string.format("0x%04X", self.memory:read(0xFFFC) + (self.memory:read(0xFFFF) * 256)))
	self:printState()
end

function VM:updateDevices()
	for _, dev in pairs(DeviceManager.devices) do
		if dev.update then
			dev:update()
		end
	end
end

-- Main update: advance CPU and handle interrupts per frame
function VM:update(dt)
	if not self.running then
		return
	end

	self.cpu:step()

	if self.cpu.halted then
		self.running = false
		return
	end

	-- -- update CPU cycles
	-- local CYCLES_PER_FRAME = 1000
	-- for i = 1, CYCLES_PER_FRAME do
	-- 	self.cycles = self.cycles +
	-- 	if self.cycles >= CYCLES_PER_FRAME then
	-- 		self.cycles = self.cycles - CYCLES_PER_FRAME
	-- 		-- service interrupts
	-- 		-- TODO: implement interrupt checking & handling
	-- 	end
	-- 	-- update connected devices
	-- 	self:updateDevices()
	-- end
end

function VM:step()
	local ret = self.cpu:step()
	-- self:updateDevices()
	return ret
end

function VM:printState()
	print(
		string.format(
			"A: %02X B: %02X H: %02X L: %02X\nSP: %04X BP: %04X PC: %04X -- SR: %02X",
			self.cpu.A,
			self.cpu.B,
			self.cpu.H,
			self.cpu.L,
			self.cpu.SP,
			self.cpu.BP,
			self.cpu.PC,
			self.cpu.SR
		)
	)
end

return VM
