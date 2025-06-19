local ExpressionParser = require("src.nyx.parser.expression")

local StatementParser

---@return StatementParser
local function getStatementParser()
	if not StatementParser then
		StatementParser = require("src.nyx.parser.statement")
	end
	return StatementParser
end

---@class WhileStatementParser: BaseParser
local WhileStatement = {}

function WhileStatement:parse()
	self:expect("WHILE")
	local condition = ExpressionParser.parse(self)
	self:expect("DO")

	local body = {}
	while self.current and self.current.type ~= "END" do
		table.insert(body, getStatementParser().parse(self))
	end
	self:expect("END")

	return self:node("WhileStatement", {
		condition = condition,
		body = body,
		line = condition.line,
	})
end

return WhileStatement
