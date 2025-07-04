local class = require("middleclass")

local Interpreter = require("src.ir_interpreter")
local Nyx = require("src.nyx")

---@class SRC
local T = class("SrcClass")

function T:initialize(source)
	---@type Nyx
	local nyx = Nyx()
	local irc = nyx:compile(source)

	if not irc then
		return
	end
	print(irc)

	---@type Interpreter
	self.interpreter = Interpreter()
	self.interpreter:tokenize(irc)

	self.targetFreq = 10000
	self.accCycles = 0
	self.avgCycleCount = 34
end

function T:update(dt)
	if not self.interpreter.halted then
		local targetCycles = dt * self.targetFreq
		self.accCycles = self.accCycles + targetCycles
		while self.accCycles >= 1 and not self.interpreter.halted do
			self.interpreter:step()
			self.accCycles = self.accCycles - (self.avgCycleCount * math.random(0.1, 1))
		end
	end
end

return T
