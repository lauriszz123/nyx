local ExpressionParser

---@class PrimaryParser: BaseParser
local PrimaryParser = {}

local function getExpressionParser()
	if not ExpressionParser then
		ExpressionParser = require("src.nyx.parser.expression")
	end
	return ExpressionParser
end

function PrimaryParser:parse()
	local t = self.current
	if not t then
		self:addError("Unexpected EOF in expression", t)
	end
	if t.type == "IDENTIFIER" then
		self:advance()
		if self.current.type == "CURLY" and self.current.value == "{" then
			self:advance()
			local body = {}
			while self.current and (self.current.type ~= "CURLY" and self.current.value ~= "}") do
				local name = self:expect("IDENTIFIER").value
				self:expect("COLON")
				local expr = getExpressionParser().parse(self)
				if self.current.value ~= "}" then
					self:expect("COMMA")
				end
				table.insert(body, {
					name = name,
					value = expr,
				})
			end
			self:expect("CURLY", "}")
			return self:node("StructBody", {
				struct = t.value,
				body = body,
			})
		else
			local expr = self:node("Identifier", {
				name = t.value,
				line = t.line,
			})

			-- SUPPORT: chain of dot accesses
			while self.current and self.current.type == "DOT" do
				self:advance()
				local field = self:expect("IDENTIFIER")

				expr = self:node("FieldAccess", {
					object = expr,
					field = field.value,
					line = field.line,
				})
			end

			return expr
		end
	elseif t.type == "NUMBER" then
		self:advance()
		return self:node("NumberLiteral", {
			value = tonumber(t.value),
			line = t.line,
		})
	elseif t.type == "NIL" then
		self:advance()
		return self:node("NIL", {
			line = t.line,
		})
	elseif t.type == "STRING" then
		self:advance()
		return self:node("StringLiteral", {
			value = t.value,
			line = t.line,
		})
	elseif t.type == "PARENTHESIS" and t.value == "(" then
		self:advance()
		local e = getExpressionParser().parse(self)
		self:expect("PARENTHESIS")
		return e
	elseif t.type == "FALSE" or t.type == "TRUE" then
		self:advance()
		return self:node("BooleanLiteral", {
			value = t.value,
			line = t.line,
		})
	elseif t.type == "AND_CHAR" then
		self:advance()
		return self:node("GetAddress", {
			value = self:expect("IDENTIFIER"),
			line = t.line,
		})
	elseif t.type == "CURLY" and t.value == "{" then
		self:advance()
		local expressions = {}

		while self.current and (self.current.type ~= "CURLY" and self.current.value ~= "}") do
			local expr = getExpressionParser().parse(self)
			if self.current.value ~= "}" then
				self:expect("COMMA")
			end
			table.insert(expressions, expr)
		end
		self:expect("CURLY", "}")

		return self:node("ArrayBlock", {
			expressions = expressions,
		})
	else
		self:addError("Unexpected token in expression: " .. t.type .. ":" .. t.value, t)
	end
end

return PrimaryParser
