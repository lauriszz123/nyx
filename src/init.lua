local class = require("middleclass")

local VM = require("src.vm")
local Nyx = require("src.nyx")
local Assembler = require("src.nyx.assembler")

---@class SRC
local T = class("SrcClass")

function T:initialize(source)
	---@type Nyx
	local nyx = Nyx()
	local assembly = nyx:compile(source)
	if not assembly then
		return
	end
	-- print("ASSEMBLY:")
	-- print(assembly)

	---@type Assembler
	local assembler = Assembler(assembly)
	local bytecode = assembler:assemble()

	if bytecode then
		---@type VM
		self.vm = VM()
		self.vm:reset(bytecode)
	else
		error("WTF")
	end
end

function T:getPluginManager()
	if self.vm then
		return self.vm:getPluginManager()
	end
end

function T:update(dt)
	if self.vm then
		self.vm:cycle(dt)
	end
end

return T
