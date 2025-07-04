local class = require("middleclass")

local Lexer = class("Lexer")

local keywords = {
	["if"] = "IF",
	["then"] = "THEN",
	["else"] = "ELSE",
	["elseif"] = "ELSEIF",
	["end"] = "END",
	["let"] = "LET",
	["new"] = "NEW",
	["fn"] = "FUNCTION",
	["return"] = "RETURN",
	["while"] = "WHILE",
	["for"] = "FOR",
	["in"] = "IN",
	["do"] = "DO",
	["break"] = "BREAK",
	["continue"] = "CONTINUE",
	["switch"] = "SWITCH",
	["case"] = "CASE",
	["default"] = "DEFAULT",
	["try"] = "TRY",
	["catch"] = "CATCH",
	["finally"] = "FINALLY",
	["not"] = "NOT",
	["and"] = "AND",
	["or"] = "OR",
	["true"] = "TRUE",
	["false"] = "FALSE",
	["nil"] = "NIL",
	["struct"] = "STRUCT",
	["impl"] = "IMPL",
	["enum"] = "ENUM",
	["import"] = "IMPORT",
	["const"] = "CONST",
	["of"] = "OF",
}

-- Constructor
function Lexer:initialize(source, isAsm)
	self.isAsm = isAsm
	self.source = source
	self.position = 1
	self.line = 1
	self.column = 1
	self.current_char = source:sub(self.position, self.position)
end

-- Function to advance the lexer by one character
function Lexer:advance()
	-- Check if the current character is a newline
	-- and update the line and column counters accordingly
	if self.current_char == "\n" then
		self.line = self.line + 1
		self.column = 1
	else
		self.column = self.column + 1
	end
	-- Move to the next character
	self.position = self.position + 1
	-- Check if we are at the end of the source string
	if self.position > #self.source then
		self.current_char = nil
	else
		self.current_char = self.source:sub(self.position, self.position)
	end
end

-- Function to skip whitespace characters
function Lexer:skip_whitespace()
	while self.current_char and self.current_char:match("%s") do
		self:advance()
	end
end

-- Function to create a token
function Lexer:create_token(type, value)
	return { type = type, value = value, line = self.line, col = self.column - #value, col_end = self.column - 1 }
end

-- Function to tokenize a number
function Lexer:tokenize_number()
	local result = ""
	if self.current_char == "0" then
		result = result .. self.current_char
		self:advance()

		if self.current_char and (self.current_char == "x" or self.current_char == "X") then
			result = result .. self.current_char
			self:advance()

			while self.current_char and self.current_char:match("[0-9a-fA-F]") do
				result = result .. self.current_char
				self:advance()
			end

			return self:create_token("NUMBER", result)
		else
			while self.current_char and self.current_char:match("%d") do
				result = result .. self.current_char
				self:advance()
			end
			return self:create_token("NUMBER", result)
		end
	else
		while self.current_char and self.current_char:match("%d") do
			result = result .. self.current_char
			self:advance()
		end
		return self:create_token("NUMBER", result)
	end
end

-- Function to tokenize an identifier or keyword
function Lexer:tokenize_identifier()
	local result = ""
	while self.current_char and self.current_char:find("[_a-zA-Z0-9]") ~= nil do
		result = result .. self.current_char
		self:advance()
	end
	if keywords[result] then
		return self:create_token(keywords[result], result)
	end
	return self:create_token("IDENTIFIER", result)
end

-- Function to tokenize a string
function Lexer:tokenize_string()
	local result = ""
	self:advance() -- Skip the opening quote
	while self.current_char and self.current_char ~= '"' do
		result = result .. self.current_char
		self:advance()
	end
	self:advance() -- Skip the closing quote
	return self:create_token("STRING", result)
end

-- Function to tokenize a single character (operator or punctuation)
function Lexer:tokenize_single_char()
	local char = self.current_char
	self:advance()
	return self:create_token("CHAR", char)
end

-- Function to tokenize a operator or punctuation
function Lexer:tokenize_operator()
	local op = self.current_char
	self:advance()

	if op == "<" then
		if self.current_char == "-" then
			self:advance()
			return self:create_token("ARROW", "<-")
		elseif self.current_char == "=" then
			self:advance()
			return self:create_token("OPERATOR", "<=")
		end
	elseif op == ">" and self.current_char == "=" then
		self:advance()
		return self:create_token("OPERATOR", ">=")
	elseif op == "!" and self.current_char == "=" then
		self:advance()
		return self:create_token("OPERATOR", "!=")
	end

	return self:create_token("OPERATOR", op)
end

-- Function to tokenize a comment (single line)
function Lexer:tokenize_comment()
	while self.current_char and self.current_char ~= "\n" do
		self:advance()
	end
end

-- Function to tokenize an assign operator
function Lexer:tokenize_assign()
	self:advance()
	if self.current_char == "=" then
		self:advance()
		return self:create_token("OPERATOR", "==")
	end
	-- If it's just a single '=', return it as an assignment operator
	return self:create_token("ASSIGN", "=")
end

-- Function to tokenize brackets
function Lexer:tokenize_bracket()
	local result = self.current_char
	self:advance()
	return self:create_token("BRACKET", result)
end

-- Function to tokenize parenthesis
function Lexer:tokenize_parenthesis()
	local result = self.current_char
	self:advance()
	return self:create_token("PARENTHESIS", result)
end

function Lexer:tokenize_curly()
	local result = self.current_char
	self:advance()
	return self:create_token("CURLY", result)
end

-- Function to tokenize a colon
function Lexer:tokenize_colon()
	self:advance()
	return self:create_token("COLON", ":")
end

-- Function to tokenize a colon
function Lexer:tokenize_and()
	self:advance()
	return self:create_token("AND_CHAR", "&")
end

-- Function to tokenize a semicolon
function Lexer:tokenize_semicolon()
	self:advance()
	return self:create_token("SEMICOLON", ";")
end

-- Function to tokenize a comma
function Lexer:tokenize_comma()
	self:advance()
	return self:create_token("COMMA", ",")
end

-- Function to tokenize a dot
function Lexer:tokenize_dot()
	self:advance()
	return self:create_token("DOT", ".")
end

-- Function to tokenize a hash
function Lexer:tokenize_hash()
	self:advance()
	return self:create_token("HASH", "#")
end

function Lexer:reset()
	self.position = 1
	self.line = 1
	self.column = 1
	self.current_char = self.source:sub(self.position, self.position)
end

function Lexer:iter()
	return function()
		while self.current_char do
			if self.current_char:match("%s") then
				self:skip_whitespace()
			elseif self.current_char:match("%d") then
				return self:tokenize_number()
			elseif self.current_char:find("[_a-zA-Z]") ~= nil then
				return self:tokenize_identifier()
			elseif self.current_char == '"' then
				return self:tokenize_string()
			elseif self.current_char == ":" then
				return self:tokenize_colon()
			elseif self.current_char == ";" then
				if self.isAsm then
					self:tokenize_comment()
				else
					return self:tokenize_semicolon()
				end
			elseif self.current_char == "," then
				return self:tokenize_comma()
			elseif self.current_char == "." then
				return self:tokenize_dot()
			elseif self.current_char == "(" or self.current_char == ")" then
				return self:tokenize_parenthesis()
			elseif self.current_char == "[" or self.current_char == "]" then
				return self:tokenize_bracket()
			elseif self.current_char == "{" or self.current_char == "}" then
				return self:tokenize_curly()
			elseif self.current_char == "#" then
				if self.isAsm then
					return self:tokenize_hash()
				else
					self:tokenize_comment()
				end
			elseif self.current_char == "&" then
				return self:tokenize_and()
			elseif self.current_char:match("[%p]") then
				if self.current_char:match("[<>!+-/*]") then
					return self:tokenize_operator()
				elseif self.current_char == "=" then
					return self:tokenize_assign()
				else
					return self:tokenize_single_char()
				end
			else
				return self:tokenize_single_char()
			end
		end
		return nil -- No more tokens
	end
end

-- Return the Lexer class
return Lexer
