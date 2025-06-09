local ExpressionParser = require("src.nyx.parser.expression")

local ExpressionStatementParser = {}

function ExpressionStatementParser:parse()
	local expr = ExpressionParser.parse(self)
	if self.current and self.current.type == "ASSIGN" then
		local line = self.current.line
		self:advance()
		local value = ExpressionParser.parse(self)
		self:expect("SEMICOLON")
		return self:node("AssignmentStatement", {
			target = expr,
			value = value,
			line = line,
		})
	else
		self:expect("SEMICOLON")
		return self:node("ExpressionStatement", { expression = expr, line = expr.line })
	end
end

return ExpressionStatementParser
