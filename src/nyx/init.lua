local class = require("middleclass")
local Lexer = require("src.nyx.lexer")
local Parser = require("src.nyx.parser")
local Validator = require("src.nyx.validator")
local Compiler = require("src.nyx.compiler")
local inspect = require("inspect")

---@class Nyx
local InitLang = class("Init")

function InitLang:initialize()
	self.version = "0.1.0"
end

function InitLang:compile(source_code)
	local lexer = Lexer(source_code)
	---@type BaseParser
	local parser = Parser(lexer)

	---@type Validator
	local validator = Validator()

	local ast = parser:parse()
	if parser:hasErrors() then
		parser:printResults()
		return
	end

	validator:validate(ast)

	if validator:hasErrors() then
		validator:printResults()
		return
	end

	-- Compile
	local compiler = Compiler()
	return compiler:generate(ast)
end

function InitLang:printVersion()
	print("Fantastic Retro VM version " .. self.version)
end

function InitLang:printWelcome()
	print("Welcome to the Fantastic Retro VM!")
	print("Type 'help' for a list of commands.")
end

return InitLang
