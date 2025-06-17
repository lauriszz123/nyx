local VM = require("src.vm")
local Nyx = require("src.nyx")
local Assembler = require("src.nyx.assembler")

local source = [[
	let x: u8 = 10;
]]

local function printreg(reg, a, b)
	print(reg .. ":", vm.cpu.A, expected.A, vm.cpu.A == expected.A)
end

local function test(src, expected)
	local nyx = Nyx()
	local assembly = nyx:compile(src)
	print(assembly)

	local bytecode = Assembler(assembly):assemble()

	---@type VM
	local vm = VM()
	vm:reset(bytecode)

	while vm.running do
		vm:step()
	end

	if expected.A then
		printreg("A", expected.A, vm.cpu.A)
	end
	if expected.B then
		printreg("B", expected.B, vm.cpu.B)
	end
	if expected.HL then
		printreg("HL", expected.HL, vm.cpu.HL)
	end
end

test(source, {
	A = 10,
})
