local VM = require("src.vm")
local Nyx = require("src.nyx")
local Assembler = require("src.nyx.assembler")

local function printreg(reg, a, b)
	print(reg .. ":", a, b, a == b)
end

local function test(src, expected)
	---@type Nyx
	local nyx = Nyx()
	local assembly = nyx:compile(src)
	if not assembly then
		return
	end
	print(assembly)

	---@type Assembler
	local assembler = Assembler(assembly)
	local bytecode = assembler:assemble()

	if bytecode then
		---@type VM
		local vm = VM()
		vm:reset(bytecode)

		local steps = 0

		while vm.running do
			vm:step()
			steps = steps + 1
		end

		print("CPU RAN FOR:", steps .. " steps")

		if expected.A then
			printreg("A", expected.A, vm.cpu.A)
		end
		if expected.B then
			printreg("B", expected.B, vm.cpu.B)
		end
	end
end

test(
	[[
	let x: u8 = 10;
]],
	{
		A = 10,
	}
)

test(
	[[
	let x: u8 = 20;

	x + 10;
]],
	{
		A = 30,
	}
)
