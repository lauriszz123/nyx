local ExpressionParser = require("src.nyx.parser.expression")
local PrimaryParser = require("src.nyx.parser.primary")

local LetParser = {}

function LetParser:parse()
	self:expect("LET")

	local nameTok = self:expect("IDENTIFIER")
	self:expect("COLON")
	local varType = self:expect("IDENTIFIER").value

	local arraySize
	if self.current.type == "BRACKET" then
		self:expect("BRACKET", "[")
		arraySize = PrimaryParser.parse(self)
		self:expect("BRACKET", "]")
	end

	local value
	if self.current.type == "ASSIGN" then
		self:advance()
		local expr = ExpressionParser.parse(self)
		value = expr
	end

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

return LetParser
