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

local function checkCodeSnippet(desc, code)
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

checkCodeSnippet('ARRAY DECLARATION', [[
  let arr: u8[0xFF];
]])

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
--
-- checkCodeSnippet('CLASS DEFINITION WITH FIELDS', [[
--   class Rectangle
--     let x: u8;
--
--     function init(x: u8, y: u8, width: u8, height: u8)
--       self.x = x;
--     end
--   end
--
--   let rect: Rectangle = new Rectangle(10, 10, 100, 100);
--   rect.x = 10;
-- ]])
--
-- checkCodeSnippet('CLASS DEFINITION WITH METHODS', [[
--   class Rectangle
--     function init()
--     end
--
--     function update(dt: u8)
--     end
--     function draw()
--     end
--   end
--
--   let rect: Rectangle = new Rectangle();
--   rect.update(0);
--   rect.draw();
-- ]])
--
-- checkCodeSnippet('CLASS DEFINITION WITH BAD FIELD ACCESS', [[
--   class Test
--     let x: u8;
--     function init()
--       self.y = 0;
--     end
--   end
--
--   let t: Test = new Test();
--   t.y = 0;
--   t.x = 10;
-- ]])
--
-- checkCodeSnippet('CLASS DEFINITION WITH BAD METHOD ACCESS', [[
--   class Test
--     let x: u8;
--     function init()
--     end
--
--     function print()
--     end
--   end
--
--   let t: Test = new Test();
--   t.x();
--   t.print();
--   t.print = 0;
-- ]])
