local Nyx = require("src.nyx")
local Interpreter = require("src.ir_interpreter")

---@param src string
---@param expectedfunc nil | fun(intr: Interpreter): nil
local function test(src, expectedfunc)
	print("=== RUNNING TEST ===")
	print("SOURCE:")
	print(src)
	print()
	---@type Nyx
	local nyx = Nyx()
	local irc = nyx:compile(src)
	if not irc then
		return
	end
	print("ASSEMBLY:")
	print(irc)

	---@type Interpreter
	local interpreter = Interpreter()
	interpreter:tokenize(irc)
	interpreter:run()

	if expectedfunc then
		expectedfunc(interpreter)
	end

	print("===   ===")
	print()
end

-- Start of tests
test(
	[[
	let x: u8 = 10;
]],
	function(interpreter)
		local ptr = interpreter.globals["x"].pointer
		if interpreter.memory:read(ptr) == 10 then
			print("Passed!")
		else
			print("Failed!")
		end
	end
)

test(
	[[
	let x: u8 = 20;

	x + 10;
]],
	function(interpreter)
		local ptr = interpreter.globals["x"].pointer
		if interpreter.memory:read(ptr) == 20 and interpreter:pop_u8() == 30 then
			print("Passed!")
		else
			print("Failed!")
		end
	end
)

test(
	[[
	let x: u8 = 20;

	x = x + 10;
]],
	function(interpreter)
		local ptr = interpreter.globals["x"].pointer
		if interpreter.memory:read(ptr) == 30 then
			print("Passed!")
		else
			print("Failed!")
		end
	end
)

test(
	[[
	poke(0x1000, 0xDE);
]],
	function(interpreter)
		if interpreter.memory:read(0x1000) == 0xDE then
			print("Passed!")
		else
			print("Failed!")
		end
	end
)

test(
	[[
	let x: u8 = 0xDE;
	poke(0x1000, x);
]],
	function(interpreter)
		local ptr = interpreter.globals["x"].pointer
		if interpreter.memory:read(0x1000) == interpreter.memory:read(ptr) then
			print("Passed!")
		else
			print("Failed!")
		end
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
	function(interpreter)
		if interpreter.memory:read(0x3000) == 0x21 then
			print("Passed!")
		else
			print("Failed!")
			print("0x3000: " .. interpreter.memory:read(0x3000))
		end
	end
)

test(
	[[
	let testStr: str = "Hello, world!";
]],
	function(interpreter)
		local str = ""
		local expected = "Hello, world!"

		local strPtr = interpreter.globals["!str_0"].pointer

		while interpreter.memory:read(strPtr) ~= 0x00 do
			local byte = interpreter.memory:read(strPtr)
			str = str .. string.char(byte)
			strPtr = strPtr + 1
		end

		if str == expected then
			print("Passed!")
		else
			print("Failed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1000) ~= 0x10 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1001) ~= 0x20 then
			print("Failed!")
			return
		end

		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1000) ~= 0x20 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1001) ~= 0x30 then
			print("Failed!")
			return
		end

		print("Passed!")
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 == 1 then
	poke(0x1000, 0x20);
end
]],
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x20 then
			print("Failed!")
			return
		end
		print("Passed!")
	end
)

test(
	[[
poke(0x1001, 0xD0);
if 1 == 0 then
	poke(0x1001, 0x20);
end
]],
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x00 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x30 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x20 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x30 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x30 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x20 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x30 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x20 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x30 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x20 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x30 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x20 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x20 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		if interpreter.memory:read(0x1001) ~= 0xD0 then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1000) ~= 0x30 then
			print("Failed!")
			return
		end
		print("Passed!")
	end
)

test(
	[[
for i = 0, 10 do
	poke(0x1000 + i, i);
end
]],
	function(interpreter)
		for i = 0, 9 do
			if interpreter.memory:read(0x1000 + i) ~= i then
				print("Failed!")
				return
			end
		end
		if interpreter.memory:read(0x100A) ~= 0x00 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		for i = 0, 4 do
			if interpreter.memory:read(0x1000 + i) ~= 0xFF then
				print("Failed!")
				return
			end
		end
		for i = 5, 9 do
			if interpreter.memory:read(0x1000 + i) ~= i then
				print("Failed!")
				return
			end
		end
		if interpreter.memory:read(0x100A) ~= 0x00 then
			print("Failed!")
			return
		end
		print("Passed!")
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
	function(interpreter)
		for i = 0, 9 do
			if interpreter.memory:read(0x1000 + i) ~= i then
				print("Failed!")
				return
			end
		end
		if interpreter.memory:read(0x100A) ~= 0x00 then
			print("Failed!")
			return
		end
		print("Passed!")
	end
)

test(
	[[
fn test(byte: u8, pointer: ptr)
	poke(pointer, byte);
end

test(0xBE, 0x1000);
]],
	function(interpreter)
		if interpreter.memory:read(0x1000) ~= 0xBE then
			print("Failed!")
			return
		end
		print("Passed!")
	end
)

test(
	[[
fn test(pointer: ptr, byte: u8)
	poke(pointer, byte);
end

test(0x1000, 0xBE);
]],
	function(interpreter)
		if interpreter.memory:read(0x1000) ~= 0xBE then
			print("Failed!")
			return
		end
		print("Passed!")
	end
)

test(
	[[
fn test(byte2: u8, pointer: ptr, byte: u8)
	poke(pointer, byte);
	poke(pointer + 1, byte2);
end

test(0xEF, 0x1000, 0xBE);
]],
	function(interpreter)
		if interpreter.memory:read(0x1000) ~= 0xBE then
			print("Failed!")
			return
		end
		if interpreter.memory:read(0x1001) ~= 0xEF then
			print("Failed!")
			return
		end
		print("Passed!")
	end
)

test(
	[[
fn strlen(): u8
	let len: u8 = 0;
	let pow: u8 = 0;

	while len < 5 do
		poke(0x1000 + len, len);

		pow = len * 2;
		poke(0x2000 + len, pow);

		len = len + 1;
	end

	return len;
end

strlen();
]],
	function(cpu)
		for i = 1, 5 do
			local got = cpu.memory:read(0x1000 + (i - 1))
			if i - 1 ~= got then
				print(i .. " -> ", "FAILED!")
				print("Expected:", i)
				print("Got:", got)
				return
			else
				print(i .. " -> ", "PASSED!")
			end

			got = cpu.memory:read(0x2000 + (i - 1))
			if (i - 1) * 2 ~= got then
				print(i .. " -> ", "FAILED!")
				print("Expected:", i)
				print("Got:", got)
				return
			else
				print(i .. " -> ", "PASSED!")
			end
		end
	end
)

test(
	[[
fn peek()
	let hello: str = "HELLO";
	poke(0x1000, peek(hello, 1));
end

peek();
]],
	function(interpreter)
		local hello = "HELLO"
		local char = 2
		if hello:sub(char, char):byte() ~= interpreter.memory:read(0x1000) then
			print("Failed!")
			return
		end
		print("Passed!")
	end
)

test(
	[[
fn strlen(string: str): u8
	let len: u8 = 0;
	let currChar: u8 = peek(string, len);

	while currChar != 0x00 do
		poke(0x1000 + len, currChar);
		len = len + 1;
		currChar = peek(string, len);
	end

	return len;
end

strlen("HELLO");
]],
	function(interpreter)
		local hello = "HELLO"
		for i = 1, #hello do
			local chr = hello:sub(i, i)
			local got = interpreter.memory:read(0x1000 + (i - 1))
			if chr:byte() ~= got then
				print(chr .. " -> ", "FAILED!")
				print("Expected:", chr)
				print("Got:", got)
				return
			else
				print(chr .. " -> ", "PASSED!")
			end
		end
		if interpreter.returnValue and interpreter.returnValue == 5 then
			print("Return value passed!")
		end
	end
)

test(
	[[
struct Test {
	test: u8
}

Test.test = 10;
]],
	function(interpreter) end
)

-- test(
-- 	[[
-- struct Test
-- 	test: u8;
-- end
--
-- Test.test = 10;
--
-- poke(0x1000, Test.test);
-- ]],
-- 	{},
-- 	function(cpu)
-- 		printreg("29", 10, cpu.memory:read(29))
-- 		printreg("0x1000", 10, cpu.memory:read(0x1000))
-- 	end
-- )
--
-- test(
-- 	[[
-- let array: u8[5] = {
-- 	1, 2, 3, 4, 5
-- };
-- ]],
-- 	{},
-- 	function(cpu)
-- 		printreg("29", 10, cpu.memory:read(29))
-- 		printreg("0x1000", 10, cpu.memory:read(0x1000))
-- 	end
-- )
--
-- test(love.filesystem.read("tests/source.nyx"), {}, function(cpu) end)
