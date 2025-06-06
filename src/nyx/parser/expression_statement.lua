local ExpressionParser = require("src.nyx.parser.expression")

local ExpressionStatementParser = {}

function ExpressionStatementParser:parse()
	local expr = ExpressionParser.parse(self)
	if self.current and self.current.type == "ASSIGN" then
		self:advance()
		local value = ExpressionParser.parse(self)
		self:expect("SEMICOLON")
		return self:node("AssignmentStatement", {
			target = expr,
			value = value,
		})
	else
		self:expect("SEMICOLON")
		return self:node("ExpressionStatement", { expression = expr })
	end
end

return ExpressionStatementParser
