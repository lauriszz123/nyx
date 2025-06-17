local VM = require("src.vm")
local Nyx = require("src.nyx")
local Assembler = require("src.nyx.assembler")

local function printreg(reg, a, b)
	print(reg .. ":", a, b, a == b)
end

---@param src string
---@param expected table
---@param expectedfunc nil | fun(cpu: CPU): nil
local function test(src, expected, expectedfunc)
	print("=== RUNNING TEST ===")
	print("SOURCE:")
	print(src)
	print()
	---@type Nyx
	local nyx = Nyx()
	local assembly = nyx:compile(src)
	if not assembly then
		return
	end
	print("ASSEMBLY:")
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

		if expectedfunc then
			expectedfunc(vm.cpu)
		end
	end
	print("===   ===")
	print()
end

test(
	[[
	let x: u8 = 10;
]],
	{
		A = 10,
	},
	function(cpu)
		printreg("x", 10, cpu.memory:read(6))
	end
)

test(
	[[
	let x: u8 = 20;

	x + 10;
]],
	{
		A = 30,
	},
	function(cpu)
		printreg("x", 20, cpu.memory:read(14))
	end
)

test(
	[[
	let x: u8 = 20;

	x = x + 10;
]],
	{
		A = 30,
	},
	function(cpu)
		printreg("x", 30, cpu.memory:read(17))
	end
)
