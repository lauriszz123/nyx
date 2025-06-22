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

-- Start of tests
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
	let testStr: str = "Hello, world!";
]],
	{},
	function(cpu)
		local hello = "Hello, world!"
		local err = false
		printreg("str pointer", 9, cpu.memory:read(8))
		for i = 1, #hello do
			local byte = hello:sub(i, i):byte()
			if byte ~= cpu.memory:read(8 + i) then
				print("STR NOT STORED CORRECTLY!")
				print("I:", i)
				print(byte, cpu.memory:read(8 + i))
				err = true
				break
			end
		end

		if not err then
			print("Passed!")
		end
	end
)

test(
	[[
	fn variants(byte: u8)
		poke(0x1000, byte);
	end

	fn variants(pointer: ptr)
		poke(pointer, 0x20);
	end

	variants(0x10);
	variants(0x1001);
]],
	{},
	function(cpu)
		printreg("First variant", 0x10, cpu.memory:read(0x1000))
		printreg("Second variant", 0x20, cpu.memory:read(0x1001))
	end
)

test(
	[[
	fn variants(byte: u8, byte2: u8)
		poke(0x1000, byte + byte2);
	end

	fn variants(pointer: ptr, byte2: u8)
		poke(pointer, 0x20 + byte2);
	end

	variants(0x10, 0x10);
	variants(0x1001, 0x10);
]],
	{},
	function(cpu)
		printreg("First variant", 0x20, cpu.memory:read(0x1000))
		printreg("Second variant", 0x30, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 == 1 then
	poke(0x1000, 0x20);
end
]],
	{},
	function(cpu)
		printreg("true", 0x20, cpu.memory:read(0x1000))
		printreg("Not modified?", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 == 0 then
	poke(0x1001, 0x20);
end
]],
	{},
	function(cpu)
		printreg("false", 0x00, cpu.memory:read(0x1000))
		printreg("Not modified?", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 == 0 then
	poke(0x1001, 0x20);
else
	poke(0x1000, 0x30);
end
]],
	{},
	function(cpu)
		printreg("false", 0x30, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 == 1 then
	poke(0x1000, 0x20);
else
	poke(0x1001, 0x30);
end

]],
	{},
	function(cpu)
		printreg("true", 0x20, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 != 1 then
	poke(0x1001, 0x20);
else
	poke(0x1000, 0x30);
end
]],
	{},
	function(cpu)
		printreg("false", 0x30, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 < 1 then
	poke(0x1001, 0x20);
else
	poke(0x1000, 0x30);
end
]],
	{},
	function(cpu)
		printreg("false", 0x30, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 < 2 then
	poke(0x1000, 0x20);
else
	poke(0x1001, 0x30);
end
]],
	{},
	function(cpu)
		printreg("true", 0x20, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 < 0 then
	poke(0x1001, 0x20);
else
	poke(0x1000, 0x30);
end
]],
	{},
	function(cpu)
		printreg("false", 0x30, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 <= 1 then
	poke(0x1000, 0x20);
else
	poke(0x1001, 0x30);
end
]],
	{},
	function(cpu)
		printreg("true", 0x20, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 <= 0 then
	poke(0x1001, 0x20);
else
	poke(0x1000, 0x30);
end
]],
	{},
	function(cpu)
		printreg("false", 0x30, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 > 0 then
	poke(0x1000, 0x20);
else
	poke(0x1001, 0x30);
end
]],
	{},
	function(cpu)
		printreg("true", 0x20, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 > 2 then
	poke(0x1001, 0x20);
else
	poke(0x1000, 0x30);
end
]],
	{},
	function(cpu)
		printreg("false", 0x30, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 >= 1 then
	poke(0x1000, 0x20);
else
	poke(0x1001, 0x30);
end
]],
	{},
	function(cpu)
		printreg("true", 0x20, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 >= 0 then
	poke(0x1000, 0x20);
else
	poke(0x1001, 0x30);
end
]],
	{},
	function(cpu)
		printreg("true", 0x20, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 >= 2 then
	poke(0x1001, 0x20);
else
	poke(0x1000, 0x30);
end
]],
	{},
	function(cpu)
		printreg("false", 0x30, cpu.memory:read(0x1000))
		printreg("0x1001", 0xD0, cpu.memory:read(0x1001))
	end
)

test(
	[[
for i = 0, 10 do
	poke(0x1000 + i, i);
end
]],
	{},
	function(cpu)
		for i = 0, 9 do
			printreg(0x1000 + i, i, cpu.memory:read(0x1000 + i))
		end
		printreg(0x100A, 0x00, cpu.memory:read(0x100A))
	end
)

test(
	[[
fn test(byte: u8)
	for i = 0, byte do
		if i < 5 then
			poke(0x1000 + i, 0xFF);
		else
			poke(0x1000 + i, i);
		end
	end
end

test(10);
]],
	{},
	function(cpu)
		for i = 0, 4 do
			printreg(0x1000 + i, 0xFF, cpu.memory:read(0x1000 + i))
		end
		for i = 5, 9 do
			printreg(0x1000 + i, i, cpu.memory:read(0x1000 + i))
		end
		printreg(0x100A, 0x00, cpu.memory:read(0x100A))
	end
)

test(
	[[
let i: u8 = 0;
while i < 10 do
	poke(0x1000 + i, i);
	i = i + 1;
end
]],
	{},
	function(cpu)
		for i = 0, 9 do
			printreg(0x1000 + i, i, cpu.memory:read(0x1000 + i))
		end
		printreg(0x100A, 0x00, cpu.memory:read(0x100A))
	end
)
