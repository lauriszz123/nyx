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

	if printAst then
		print(inspect(ast))
	end

	local validator = Validator()
	local results = validator:check(ast)

	validator:printResults()

	return results
end

local function checkCodeSnippet(desc, code)
	print("=== " .. desc .. " ===")
	local results = runTypeChecker(code, false)
	print("Errors found:" .. #results.errors)
	print("Warnings found:" .. #results.warnings)
	print()
	return results
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

-- checkCodeSnippet( "ARRAY DECLARATION",
-- 	[[
--   let arr: u8[0xFF];
-- ]]
-- )

-- checkCodeSnippet("SOURCE CHECK", love.filesystem.read("/tests/source.nyx"))
