local class = require("middleclass")

local Lexer = require("src.nyx.lexer")

local IR_CODES = {
	const_u8 = {
		argc = 1,
	},
	define_global = {
		argc = 2,
	},
	halt = {
		argc = 0,
	},
}

---@class Interpreter
local Interpreter = class("Interpreter")

function Interpreter:initialize(source)
	local lexer = Lexer(source, true)
	self.tokens = {}
	for token in lexer:iter() do
		table.insert(self.tokens, token)
	end

	self.position = 1
	self.current = self.tokens[self.position]

	self.irTree = {}

	self.halted = false
end

function Interpreter:advance()
	self.position = self.position + 1
	self.current = self.tokens[self.position]
	return self.current
end

-- Peek at the next token without advancing
function Interpreter:peek(offset)
	offset = offset or 0
	return self.tokens[self.position + offset]
end

function Interpreter:tokenize()
	while self.current do
		local currType = self:peek().type
		if currType == "IDENTIFIER" then
			local name = self:peek().value
			self:advance()

			print(name)

			local ir = IR_CODES[name]
			if not ir then
				error("Unknown IR: " .. name)
			end
			local args = {}

			for i = 1, ir.argc do
				if self.current.type == "IDENTIFIER" or self.current.type == "NUMBER" then
					table.insert(args, self.current.value)
					self:advance()
				else
					error("Unknown arg type: " .. self.current.type)
				end

				if i < ir.argc then
					if self.current.type ~= "COMMA" then
						error("Expected a comma!")
					else
						self:advance()
					end
				end
			end

			table.insert(self.irTree, {
				name = name,
				args = args,
			})
		else
			error("Unknown type: " .. currType)
		end
	end
end

function Interpreter:run()
	for i = 1, #self.irTree do
	end
end

return Interpreter
