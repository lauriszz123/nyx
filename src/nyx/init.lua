local class = require("middleclass")
local Lexer = require("src.nyx.lexer")
local Parser = require("src.nyx.parser")
local TypeChecker = require("src.nyx.validator")
local Compiler = require("src.nyx.compiler")
local inspect = require("inspect")

local InitLang = class("Init")

function InitLang:initialize()
	self.version = "0.1.0"
end

function InitLang:compile(source_code)
	local lexer = Lexer(source_code)
	for token in lexer:iter() do
		print(token.type, token.value, token.line, token.col, token.col_end)
	end

	-- Create a new lexer instance with the source code
	lexer:reset()
	local parser = Parser(lexer)
	local checker = TypeChecker()
	local ast = parser:parse()
	local errors = checker:check(ast)
	print(inspect(ast))

	-- Compile
	--local compiler = Compiler()

	--return compiler:compile(ast)
	return nil, errors
end

function InitLang:printVersion()
	print("Fantastic Retro VM version " .. self.version)
end

function InitLang:printWelcome()
	print("Welcome to the Fantastic Retro VM!")
	print("Type 'help' for a list of commands.")
end

return InitLang
