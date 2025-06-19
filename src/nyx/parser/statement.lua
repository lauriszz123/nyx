local StructParser = require("src.nyx.parser.struct")
local ImplParser = require("src.nyx.parser.impl")
local FunctionParser = require("src.nyx.parser.function")
local LetParser = require("src.nyx.parser.let")
local IfParser = require("src.nyx.parser.if")
local WhileParser = require("src.nyx.parser.while")
local ForParser = require("src.nyx.parser.for")
local ReturnParser = require("src.nyx.parser.return")
local ExpressionStatementParser = require("src.nyx.parser.expression_statement")

---@class StatementParser: BaseParser
local StatementParser = {}

function StatementParser:parse()
	local t = self.current.type
	if t == "STRUCT" then
		return StructParser.parse(self)
	elseif t == "IMPL" then
		return ImplParser.parse(self)
	elseif t == "FUNCTION" then
		return FunctionParser.parse(self)
	elseif t == "RETURN" then
		return ReturnParser.parse(self)
	elseif t == "IF" then
		return IfParser.parse(self)
	elseif t == "WHILE" then
		return WhileParser.parse(self)
	elseif t == "FOR" then
		return ForParser.parse(self)
	elseif t == "TRY" then
		-- return self:parse_try()
	elseif t == "LET" then
		return LetParser.parse(self)
	else
		return ExpressionStatementParser.parse(self)
	end
end

return StatementParser
