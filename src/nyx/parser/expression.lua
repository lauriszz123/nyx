local PrimaryParser = require("src.nyx.parser.primary")

local ExpressionParser = {}

local precedences = {
	["or"] = { prec = 1, assoc = "left" },
	["and"] = { prec = 2, assoc = "left" },
	["=="] = { prec = 3, assoc = "left" },
	["!="] = { prec = 3, assoc = "left" },
	["<"] = { prec = 4, assoc = "left" },
	[">"] = { prec = 4, assoc = "left" },
	["<="] = { prec = 4, assoc = "left" },
	[">="] = { prec = 4, assoc = "left" },
	["+"] = { prec = 5, assoc = "left" },
	["-"] = { prec = 5, assoc = "left" },
	["*"] = { prec = 6, assoc = "left" },
	["/"] = { prec = 6, assoc = "left" },
}

local function parse_call(self)
	local expr = PrimaryParser.parse(self)
	while self.current and self.current.type == "PARENTHESIS" and self.current.value == "(" do
		-- function call
		self:advance()
		local args = {}
		while self.current and not (self.current.type == "PARENTHESIS" and self.current.value == ")") do
			table.insert(args, ExpressionParser.parse(self))
			if self.current.type == "COMMA" then
				self:advance()
			end
		end
		self:expect("PARENTHESIS") -- ')'
		expr = self:node("CallExpression", {
			callee = expr,
			arguments = args,
			line = expr.line,
		})
	end
	return expr
end

local function parse_unary(self)
	if self.current.type == "NOT" or (self.current.type == "OPERATOR" and self.current.value == "-") then
		local op = self.current.value
		local line = self.current.line
		self:advance()
		local expr = parse_unary(self)
		return self:node("UnaryExpression", { operator = op, argument = expr, line = line })
	end
	return parse_call(self)
end

local function parse_binary(self, minPrec)
	local left = parse_unary(self)
	while true do
		local tok = self.current
		if not tok then
			break
		end
		local op = tok.value
		local line = tok.line
		local info = precedences[op]
		if not info or info.prec < minPrec then
			break
		end
		self:advance()
		local nextMin = info.prec + ((info.assoc == "left") and 1 or 0)
		local right = parse_binary(self, nextMin)
		left = self:node("BinaryExpression", {
			operator = op,
			left = left,
			right = right,
			line = line,
		})
	end
	return left
end

function ExpressionParser:parse()
	return parse_binary(self, 0)
end

return ExpressionParser
