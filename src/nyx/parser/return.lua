local ExpressionParser = require("src.nyx.parser.expression")

---@class ReturnStatement: BaseParser
local ReturnStatement = {}

function ReturnStatement:parse()
	self:expect("RETURN")
	local line = self.current.line
	local value
	if
		self.current
		and self.current.type ~= "END"
		and self.current.type ~= "ELSE"
		and self.current.type ~= "CATCH"
		and self.current.type ~= "FINALLY"
	then
		value = ExpressionParser.parse(self)
		self:expect("SEMICOLON")
	else
		if self.current.type == "SEMICOLON" then
			self:advance()
		end
	end
	return self:node("ReturnStatement", { value = value, line = line })
end

return ReturnStatement
