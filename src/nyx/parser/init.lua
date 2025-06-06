local class = require("middleclass")
local AST = require("src.nyx.ast")
local StatementParser = require("src.nyx.parser.statement")

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
end

function Parser:advance()
	self.position = self.position + 1
	self.current = self.tokens[self.position]
end

function Parser:peek()
	return self.tokens[self.position + 1]
end

function Parser:expect(type, value)
	if self.current and self.current.type == type then
		if value then
			if self.current.value ~= value then
				error(
					string.format(
						"Expected token '%s' with value '%s' but got '%s' with value '%s' at line %d col %d",
						type,
						value,
						self.current and self.current.type or "EOF",
						self.current and self.current.value or "NIL",
						self.current and self.current.line or -1,
						self.current and self.current.col or -1
					)
				)
			else
				self:advance()
			end
		else
			local token = self.current
			self:advance()
			return token
		end
	else
		error(
			string.format(
				"Expected token '%s' but got '%s' at line %d col %d",
				type,
				self.current and self.current.type or "EOF",
				self.current and self.current.line or -1,
				self.current and self.current.col or -1
			)
		)
	end
end

-- AST Node creators
function Parser:node(kind, props)
	return AST.Node(kind, props)
end

-- Entry point
function Parser:parse()
	local nodes = {}
	while self.current do
		table.insert(nodes, StatementParser.parse(self))
	end
	return self:node("Program", { body = nodes })
end

return Parser
