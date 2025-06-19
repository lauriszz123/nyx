local ExpressionParser = require("src.nyx.parser.expression")

local StatementParser

---@return StatementParser
local function getStatementParser()
	if not StatementParser then
		StatementParser = require("src.nyx.parser.statement")
	end
	return StatementParser
end

---@class ForStatementParser: BaseParser
local ForStatement = {}

function ForStatement:parse()
	self:expect("FOR")
	local name = self:expect("IDENTIFIER")
	self:expect("ASSIGN")
	local start = ExpressionParser.parse(self)
	self:expect("COMMA")
	local stop = ExpressionParser.parse(self)
	self:expect("DO")

	local body = {}
	while self.current and self.current.type ~= "END" do
		table.insert(body, getStatementParser().parse(self))
	end
	self:expect("END")

	return self:node("ForStatement", {
		name = name.value,
		start = start,
		stop = stop,
		body = body,
		line = name.line,
	})
end

return ForStatement
