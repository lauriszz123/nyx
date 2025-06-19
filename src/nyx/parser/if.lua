local ExpressionParser = require("src.nyx.parser.expression")

local StatementParser

---@return StatementParser
local function getStatementParser()
	if not StatementParser then
		StatementParser = require("src.nyx.parser.statement")
	end
	return StatementParser
end

---@class IfStatementParser: BaseParser
local IfStatement = {}

function IfStatement:parse(isElseIf)
	if not isElseIf then
		self:expect("IF")
	else
		self:expect("ELSEIF")
	end

	local condition = ExpressionParser.parse(self)
	self:expect("THEN")

	local body = {}
	while
		self.current and (self.current.type ~= "END" and self.current.type ~= "ELSE" and self.current.type ~= "ELSEIF")
	do
		table.insert(body, getStatementParser().parse(self))
	end

	local elseBody
	if self.current.type == "ELSE" then
		self:expect("ELSE")
		elseBody = {}
		while self.current and self.current.type ~= "END" do
			table.insert(body, getStatementParser().parse(self))
		end
		self:expect("END")
	elseif self.current.type == "ELSEIF" then
		elseBody = IfStatement.parse(self, true)
	else
		self:expect("END")
	end

	return self:node("IfStatement", {
		condition = condition,
		body_true = body,
		body_false = elseBody,
		line = condition.line,
	})
end

return IfStatement
