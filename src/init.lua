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
end

function T:update(dt)
	if not self.interpreter.halted then
		self.interpreter:step()
	end
end

return T
