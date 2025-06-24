local Lexer = require("src.nyx.lexer")
local Parser = require("src.nyx.parser")
local Validator = require("src.nyx.validator")
local inspect = require("inspect")

local DEBUG = false

local function runTypeChecker(source, shouldFail)
	local lexer = Lexer(source)

	---@type BaseParser
	local parser = Parser(lexer)
	local ast = parser:parse()

	if parser:hasErrors() and not shouldFail then
		parser:printResults()
		return false
	end

	if DEBUG then
		print()
		print(inspect(ast))
		print()
	end

	---@type Validator
	local validator = Validator()
	validator:validate(ast)

	if validator:hasErrors() and not shouldFail then
		print()
		validator:printResults()
		print()
		return false
	end

	return true
end

local curr = 1
local failed = 0
local passed = 0

local function checkCodeSnippet(desc, code, shouldFail)
	print("=== TEST: " .. curr .. " ===")
	print("=== " .. desc .. " ===")
	if runTypeChecker(code, shouldFail) then
		passed = passed + 1
	else
		failed = failed + 1
	end
	curr = curr + 1
end

local function printResults()
	print()
	print("Nyx Tests done.")
	print("Passed:", passed .. "/" .. (curr - 1))
	print("Failed:", failed)
end

checkCodeSnippet(
	"VALID CODE",
	[[
  let x: u8 = 10;
  fn double(n: u8): u8
    return n * 2;
  end

  let result: u8 = double(x);
]]
)

checkCodeSnippet(
	"VALID CODE ASSIGNMENT",
	[[
  let x: u8 = 10;

  x = 10 * 2;
]]
)

checkCodeSnippet(
	"INVALID CODE ASSIGNMENT",
	[[
  let x: str;

  x = 10 * 2;
]],
	true
)

checkCodeSnippet(
	"TYPE MISMATCH",
	[[
  let x: u8 = "not a number";
  fn square(n: u8): u8
    return n * n;
  end
  let result: str = square(x);
]],
	true
)

checkCodeSnippet(
	"POINTER ARITHMETIC",
	[[
  let baseAddr: ptr = 0x1000;
  let offset: u8 = 16;
  let newAddr: ptr = baseAddr + offset;
]]
)

checkCodeSnippet(
	"POINTER ARITHMETIC BAD",
	[[
  let baseAddr: ptr = 0x1000;
  let offset: u8 = 16;
  let newAddr: ptr = baseAddr + offset;
  let badArith: ptr = baseAddr * offset;
]],
	true
)

checkCodeSnippet(
	"SIGNED/UNSIGNED MIXING",
	[[
  let unsigned: u8 = 200;
  let signed: s8 = -50;
  let result: s8 = unsigned + signed;
  let negate: s8 = -unsigned;
]]
)

checkCodeSnippet(
	"BOOLEAN OPERATIONS",
	[[
  let flag1: bool = 1;
  let flag2: bool = false;
  let result: bool = flag1 and flag2;
  let comparison: bool = flag1 == flag2;
]]
)

checkCodeSnippet(
	"BOOLEAN OPERATIONS BAD",
	[[
  let flag1: bool = 1;
  let flag2: bool = false;
  let result: bool = flag1 and flag2;
  let comparison: bool = flag1 == flag2;
  let badLogic: bool = 255 and 18;
]],
	true
)

checkCodeSnippet(
	"UNDEFINED VARIABLE",
	[[
  let x: u8 = y + 1;
  fn test(): u8
    return undefinedVar;
  end
]],
	true
)

checkCodeSnippet(
	"STRUCT DEFINITION",
	[[
struct Test {
	test: u8,
}

struct Test {
	test: u8
}
]]
)

checkCodeSnippet(
	"INVALID STRUCT DECLARATION FIELDS",
	[[
struct Test {
	test: unknown
}
]],
	true
)

checkCodeSnippet(
	"INVALID STRUCT DECLARATION",
	[[
struct Test {
	test: ok,
	test2: us
	test3: xx
}
]],
	true
)

checkCodeSnippet(
	"STRUCT DECLARATION 2",
	[[
struct Test1 {
	test: u8
}

struct Test2 {
	testStruct: Test1,
	value: u8
}
]]
)

checkCodeSnippet(
	"IF STATEMENT",
	[[
if 1 == 1 then
	 1 + 2 * 3;
end
]]
)

checkCodeSnippet(
	"IF STATEMENT GOOD AND BAD",
	[[
let int: u8 = 10;
let string: str = "Some string!";

if 1 then
end
if 0 then
end

if 2 then
end

if int then
end

if string then
end
]],
	true
)

checkCodeSnippet(
	"IF/ELSE STATEMENT",
	[[
if 1 then
else
end
]]
)

checkCodeSnippet(
	"IF/ELSE IF/ELSE STATEMENT",
	[[
if 1 then
elseif 0 then
else
end

if 1 then
elseif 0 then
end
]]
)

checkCodeSnippet(
	"IF/ELSE IF/ELSE STATEMENT GOOD AND BAD",
	[[
if 1 then
elseif 0 then
else
end

if 3 then
elseif 0 then
else
end

if 1 then
elseif 3 then
else
end
]],
	true
)

checkCodeSnippet(
	"WHILE CONDITION",
	[[
while 1 do
end
]]
)

checkCodeSnippet(
	"WHILE CONDITION BAD",
	[[
let x: ptr = 0x3000;

while 3 do
end


while "str" do
end

while x do
end
]],
	true
)

checkCodeSnippet(
	"FOR CONDITION",
	[[
fn test(x: u8)
	x = x * 2;
end

for x = 1, 10 do
	test(x);
end
]]
)

checkCodeSnippet(
	"FOR CONDITION BAD",
	[[
fn test(x: u8)
	x = x * 2;
end

for x = 0x1000, 10 do
	test(x);
end

for x = 0, 0x1000 do
	test(x);
end
]],
	true
)

checkCodeSnippet(
	"FUNCTION OVERLOADING",
	[[
fn test(x: u8)
	x = x * 2;
end

fn test(x: str)
end

test(0x10);
test("YES");
]]
)

checkCodeSnippet(
	"FUNCTION OVERLOADING BAD USAGE",
	[[
fn test(x: u8, y: ptr)
	x = x * 2;
end

fn test(x: str)
end

fn test(x: u8)
end

test(0x10, "ST");
test(0x10);
test(0x1000);
]],
	true
)

checkCodeSnippet(
	"ARRAY DECLARATION",
	[[
  let arr: u8[5];
]]
)

checkCodeSnippet(
	"ARRAY DECLARATION AND ASSIGNMENT",
	[[
  let arr: u8[5] = {
  	1, 2, 3, 4, 5
  };
]]
)

-- checkCodeSnippet("SOURCE CHECK", love.filesystem.read("/tests/source.nyx"))

printResults()
