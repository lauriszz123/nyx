local class = require("middleclass")

local Memory = require("src.util.memory")
local PluginManager = require("src.vm.pluginManager")
local CPU = require("src.vm.cpu")

---@class VM
local VM = class("VM")

function VM:initialize()
	---@type PluginManager
	self.pluginManager = PluginManager()

	---@type Memory
	self.memory = Memory(self.pluginManager)

	---@type CPU
	self.cpu = CPU(self.memory)

	self.accCycles = 0
	self.targetFreq = 1000000
	self.lastTime = love.timer.getTime()
	self.running = false
end

function VM:reset(bytecode, offset)
	offset = offset or 0
	self.running = true
	self.cpu:reset()

	local count = 0
	local currStr = ""
	for i = 1, #bytecode do
		self.memory:write(offset + (i - 1), bytecode[i])

		currStr = currStr .. string.format("%02X", bytecode[i]) .. " "
		count = count + 1

		if count % 8 == 0 then
			print(string.format("0x%04X: %s", offset + (i - 8), currStr))
			currStr = ""
		end
	end

	if count % 8 ~= 0 then
		print(string.format("0x%04X: %s", offset + (count - (count % 8)), currStr))
	end

	self.memory:write(0xFFFC, 0x00) -- Reset vector low byte
	self.memory:write(0xFFFF, 0x00) -- Reset vector high byte

	print()
	print("VM reset at offset: " .. string.format("0x%04X", offset))
	print("Bytecode loaded: " .. #bytecode .. " bytes")
	print("Reset vector: " .. string.format("0x%04X", self.memory:read(0xFFFC) + (self.memory:read(0xFFFF) * 256)))
	print()
end

---@return PluginManager
function VM:getPluginManager()
	return self.pluginManager
end

-- Main update: advance CPU and handle interrupts per frame
function VM:cycle(dt)
	if not self.running then
		return
	end

	local targetCycles = dt * self.targetFreq
	self.accCycles = self.accCycles + targetCycles

	while self.accCycles >= 1 do
		local cycles = self.cpu:step()
		self.accCycles = self.accCycles - cycles

		if self.cpu.halted then
			self.running = false
			return
		end
	end
end

function VM:step()
	local ret = self.cpu:step()
	if self.cpu.halted then
		self.running = false
	end
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
