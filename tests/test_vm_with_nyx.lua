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

test(
	[[
	poke(0x1000, 0xDE);
]],
	{},
	function(cpu)
		printreg("0x1000", 0xDE, cpu.memory:read(0x1000))
	end
)

test(
	[[
	let x: u8 = 0xDE;
	poke(0x1000, x);
]],
	{},
	function(cpu)
		printreg("0x1000", 0xDE, cpu.memory:read(0x1000))
	end
)

test(
	[[
	let VIDEO_MEM_CHAR: ptr = 0x3000;

	fn writeChar(byte: u8)
		poke(VIDEO_MEM_CHAR, byte);
	end

	writeChar(0x21);
]],
	{},
	function(cpu)
		printreg("0x3000 stored", 0x30, cpu.memory:read(14))
		printreg("0x3000 pointed to", 0x21, cpu.memory:read(0x3000))
	end
)

test(
	[[
	let VIDEO_MEM_CHAR: ptr = 0x3000;

	fn writeChar(byte: u8)
		poke(VIDEO_MEM_CHAR, byte);
	end

	writeChar(20 + 2 * 10 + 8);
]],
	{},
	function(cpu)
		printreg("0x3000 stored", 0x30, cpu.memory:read(29))
		printreg("0x3000 pointed to", 48, cpu.memory:read(0x3000))
	end
)
