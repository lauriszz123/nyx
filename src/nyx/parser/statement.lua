local StructParser = require("src.nyx.parser.struct")
local ImplParser = require("src.nyx.parser.impl")
local FunctionParser = require("src.nyx.parser.function")
local LetParser = require("src.nyx.parser.let")
local ReturnParser = require("src.nyx.parser.return")
local ExpressionStatementParser = require("src.nyx.parser.expression_statement")

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
		return self:parse_if()
	elseif t == "WHILE" then
		return self:parse_while()
	elseif t == "FOR" then
		return self:parse_for()
	elseif t == "TRY" then
		return self:parse_try()
	elseif t == "LET" then
		return LetParser.parse(self)
	else
		return ExpressionStatementParser.parse(self)
	end
end

return StatementParser
