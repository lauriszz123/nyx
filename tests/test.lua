local Lexer = require 'src.nyx.lexer'
local Parser = require 'src.nyx.parser'
local TypeChecker = require 'src.nyx.typecheck'
local inspect = require 'inspect'

local function runTypeChecker(source, printAst)
  print('=== RUNNING SOURCE ===')
  print(source)
  print('====              ====')

  local lexer = Lexer(source)

  local parser = Parser(lexer)
  local ast = parser:parse()

  if printAst then
    print(inspect(ast))
  end

  local typeChecker = TypeChecker()
  local results = typeChecker:check(ast)

  typeChecker:printResults()

  return results
end

local function checkCodeSnippet(desc, code, expected)
  print('=== ' .. desc .. ' ===')
  local results = runTypeChecker(code, true)
  print('Errors found:' .. #results.errors)
  print('Warnings found:' .. #results.warnings)
  print()
  return results
end

-- checkCodeSnippet('VALID CODE', [[
--   let x: u8 = 10;
--   function double(n: u8): u8
--     return n * 2;
--   end
--
--   let result: u8 = double(x);
-- ]])
--
-- checkCodeSnippet('TYPE MISMATCH', [[
--   let x: u8 = "not a number";
--   function square(n: u8): u8
--     return n * n;
--   end
--   let result: str = square(x);
-- ]])
--
-- checkCodeSnippet('POINTER ARITHMETIC', [[
--   let baseAddr: ptr = 0x1000;
--   let offset: u8 = 16;
--   let newAddr: ptr = baseAddr + offset;
--   let badArith: ptr = baseAddr * offset;
-- ]])
--
-- checkCodeSnippet('SIGNED/UNSIGNED MIXING', [[
--   let unsigned: u8 = 200;
--   let signed: s8 = -50;
--   let result: s8 = unsigned + signed;
--   let negate: s8 = -unsigned;
-- ]])
--
-- checkCodeSnippet('BOOLEAN OPERATIONS', [[
--   let flag1: bool = 1;
--   let flag2: bool = false;
--   let result: bool = flag1 and flag2;
--   let comparison: bool = flag1 == flag2;
--   let badLogic: bool = 255 and 18;
-- ]])
--
-- checkCodeSnippet('UNDEFINED VARIABLE', [[
--   let x: u8 = y + 1;
--   function test(): u8
--     return undefinedVar;
--   end
-- ]])

-- checkCodeSnippet('CLASS DEFINITION', [[
--   class Rectangle
--     function init()
--     end
--   end
--   let rect: Rectangle = new Rectangle();
-- ]])
--
-- checkCodeSnippet('CLASS INCORRECT DEFINITION', [[
--   class Rectangle
--     function someMethod()
--     end
--   end
--   let rect: Rectangle = new Rectangle();
-- ]])

checkCodeSnippet('CLASS DEFINITION WITH FIELDS', [[
  class Rectangle
    let x: u8;
    let y: u8;
    let width: u8;
    let height: u8;

    function init(x: u8, y: u8, width: u8, height: u8)
      self.x = x;
      self.y = y;
      self.width = width;
      self.height = height;
    end
  end

  let rect: Rectangle = new Rectangle(10, 10, 100, 100);
]])
