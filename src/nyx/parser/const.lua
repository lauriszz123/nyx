local ExpressionParser = require("src.nyx.parser.expression")
local PrimaryParser = require("src.nyx.parser.primary")

local ConstParser = {}

function ConstParser:parse()
	self:expect("CONST")

	local nameTok = self:expect("IDENTIFIER")
	self:expect("COLON")
	local varType = self:expect("IDENTIFIER").value

	self:expect("ASSIGN")

	local value = ExpressionParser.parse(self)

	self:expect("SEMICOLON")

	return self:node("VariableDeclaration", {
		name = nameTok.value,
		varType = varType,
		value = value,
		isArray = arraySize ~= nil,
		arraySize = arraySize,
		line = nameTok.line,
	})
end

return ConstParser
