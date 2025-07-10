local ExpressionParser = require("src.nyx.parser.expression")
local Errors = require("src.nyx.parser.errMessages")

---@class ConstParser: BaseParser
local ConstParser = {}

function ConstParser:parse()
	self:expect("CONST")

	local nameTok = self:expect("IDENTIFIER", nil, Errors.ERR_CONST_DEFINITION_NAME)
	self:expect("COLON")
	local varType = self:expect("IDENTIFIER", nil, Errors.ERR_CONST_DEFINITION_TYPE).value

	self:expect("ASSIGN", nil, Errors.ERR_CONST_DEFINITION_ASSIGNMENT)

	local value = ExpressionParser.parse(self)

	self:expect("SEMICOLON", nil, Errors.ERR_STATEMENT_SEMICOLON)

	return self:node("VariableDeclaration", {
		isConst = true,
		name = nameTok.value,
		varType = varType,
		value = value,
		line = nameTok.line,
	})
end

return ConstParser
