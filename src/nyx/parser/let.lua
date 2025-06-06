local ExpressionParser = require("src.nyx.parser.expression")

local LetParser = {}

function LetParser:parse()
	self:expect("LET")
	local nameTok = self:expect("IDENTIFIER")
	local varType, arraySize
	if self.current.type == "COLON" then
		self:advance()
		varType = self:expect("IDENTIFIER").value
		if self.current.type == "BRACKET" then
			self:expect("BRACKET", "[")
			arraySize = self:parse_primary()
			self:expect("BRACKET", "]")
		end
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
		column = nameTok.column,
	})
end

return LetParser
