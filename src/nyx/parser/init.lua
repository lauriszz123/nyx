local class = require("middleclass")
local AST = require("src.nyx.ast")
local StatementParser = require("src.nyx.parser.statement")
local ERRORS = require("src.nyx.parser.errMessages")

local Parser = class("Parser")

function Parser:initialize(lexer)
	self.tokens = {}
	self.errors = {}
	self.lexer = lexer
	for token in lexer:iter() do
		table.insert(self.tokens, token)
	end
	self.position = 1
	self.current = self.tokens[self.position]
end

function Parser:addError(message, node)
	table.insert(self.errors, {
		message = message,
		line = node.line,
	})
	error()
end

function Parser:advance()
	self.position = self.position + 1
	self.current = self.tokens[self.position]
end

function Parser:peek()
	return self.tokens[self.position + 1]
end

function Parser:expect(type, value, errFunc)
	local errMessage
	if self.current and self.current.type == type then
		if value then
			if self.current.value ~= value then
				errMessage = (errFunc or ERRORS.ERR_TOK_VAL)(
					type,
					self.current and self.current.type or "EOF",
					value,
					self.current and self.current.value or "EOF"
				)
				self:addError(errMessage, self.current)
			else
				self:advance()
			end
		else
			local token = self.current
			self:advance()
			return token
		end
	else
		errMessage = (errFunc or ERRORS.ERR_TOK)(type, self.current and self.current.type or "EOF")
		self:addError(errMessage, self.current)
	end
end

-- AST Node creators
function Parser:node(kind, props)
	return AST.Node(kind, props)
end

-- Entry point
function Parser:parse_top()
	local nodes = {}
	while self.current do
		table.insert(nodes, StatementParser.parse(self))
	end
	return self:node("Program", { body = nodes })
end

function Parser:parse()
	local ok, ast = pcall(self.parse_top, self)
	if not ok then
		print("error: ", ast)
		return
	end

	return ast
end

function Parser:hasErrors()
	return #self.errors > 0
end

function Parser:printResults()
	if self:hasErrors() then
		print("=== PARSER ERRORS ===")
		for _, err in ipairs(self.errors) do
			print(string.format("Error at line %d: %s", err.line, err.message))
		end
	else
		print("No issues found!")
	end
end

return Parser
