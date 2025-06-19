local Lexer = require("src.nyx.lexer")
local Parser = require("src.nyx.parser")
local Validator = require("src.nyx.validator")
local inspect = require("inspect")

local function runTypeChecker(source, printAst)
	print("=== RUNNING SOURCE ===")
	print(source)
	print("====              ====")

	local lexer = Lexer(source)

	local parser = Parser(lexer)
	local ast = parser:parse()

	if parser:hasErrors() then
		print()
		parser:printResults()
		print()
		return
	end

	if printAst then
		print()
		print(inspect(ast))
		print()
	end

	---@type Validator
	local validator = Validator()
	validator:validate(ast)

	print()
	validator:printResults()
	print()
end

local function checkCodeSnippet(desc, code)
	print("=== " .. desc .. " ===")
	runTypeChecker(code, false)
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
]]
)

checkCodeSnippet(
	"TYPE MISMATCH",
	[[
  let x: u8 = "not a number";
  fn square(n: u8): u8
    return n * n;
  end
  let result: str = square(x);
]]
)

checkCodeSnippet(
	"POINTER ARITHMETIC",
	[[
  let baseAddr: ptr = 0x1000;
  let offset: u8 = 16;
  let newAddr: ptr = baseAddr + offset;
  let badArith: ptr = baseAddr * offset;
]]
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
  let badLogic: bool = 255 and 18;
]]
)

checkCodeSnippet(
	"UNDEFINED VARIABLE",
	[[
  let x: u8 = y + 1;
  fn test(): u8
    return undefinedVar;
  end
]]
)

checkCodeSnippet(
	"STRUCT DEFINITION",
	[[
struct Test
	test: u8;
end
]]
)

checkCodeSnippet(
	"INVALID STRUCT DECLARATION FIELDS",
	[[
struct Test
	test: unknown;
end
]]
)

checkCodeSnippet(
	"STRUCT DECLARATION 2",
	[[
struct Test1
	test: u8;
end
struct Test2
	testStruct: Test1;
	value: u8;
end
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
]]
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
]]
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
]]
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
]]
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
]]
)

-- checkCodeSnippet( "ARRAY DECLARATION",
-- 	[[
--   let arr: u8[0xFF];
-- ]]
-- )

-- checkCodeSnippet("SOURCE CHECK", love.filesystem.read("/tests/source.nyx"))
