local ERR_MESSAGE = require("src.nyx.parser.errMessages")

local StatementParser

local FunctionParser = {}

local function getStatementParser()
	if not StatementParser then
		StatementParser = require("src.nyx.parser.statement")
	end
	return StatementParser
end

local function parseParameters(self)
	local params = {}
	while self.current and not (self.current.type == "PARENTHESIS" and self.current.value == ")") do
		if self.current.type == "IDENTIFIER" then
			local name = self.current.value
			self:advance()
			local typ
			if self.current.type == "COLON" then
				self:advance()
				typ = self:expect("IDENTIFIER").value
			end
			table.insert(params, { name = name, type = typ })
			if self.current.type == "COMMA" then
				self:advance()
			end
		else
			break
		end
	end
	return params
end

function FunctionParser:parse(inImpl)
	self:expect("FUNCTION", nil, inImpl == true and ERR_MESSAGE.IN_IMPL)
	local name = self:expect("IDENTIFIER").value
	self:expect("PARENTHESIS") -- '('
	local params = parseParameters(self)
	self:expect("PARENTHESIS") -- ')'
	local returnType
	if self.current and self.current.type == "COLON" then
		self:advance()
		if self.current.type == "NIL" then
			self:advance()
			returnType = "nil"
		else
			returnType = self:expect("IDENTIFIER").value
		end
	end
	local body = {}
	while self.current and self.current.type ~= "END" do
		table.insert(body, getStatementParser().parse(self))
	end
	self:expect("END")
	return self:node("FunctionDeclaration", { name = name, params = params, returnType = returnType, body = body })
end

return FunctionParser
