local ExpressionParser = require("src.nyx.parser.expression")

local ReturnStatement = {}

function ReturnStatement:parse()
	self:expect("RETURN")
	local value
	if
		self.current
		and self.current.type ~= "END"
		and self.current.type ~= "ELSE"
		and self.current.type ~= "CATCH"
		and self.current.type ~= "FINALLY"
	then
		value = ExpressionParser.parse(self)
	end
	self:expect("SEMICOLON")
	return self:node("ReturnStatement", { value = value })
end

return ReturnStatement
