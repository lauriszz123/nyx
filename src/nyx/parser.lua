local class = require 'middleclass'
local AST = require 'src.nyx.ast'

local Parser = class("Parser")

local precedences = {
	["or"]  = { prec = 1, assoc = "left" },
	["and"] = { prec = 2, assoc = "left" },
	["=="]  = { prec = 3, assoc = "left" },
	["!="]  = { prec = 3, assoc = "left" },
	["<"]   = { prec = 4, assoc = "left" },
	[">"]   = { prec = 4, assoc = "left" },
	["<="]  = { prec = 4, assoc = "left" },
	[">="]  = { prec = 4, assoc = "left" },
	["+"]   = { prec = 5, assoc = "left" },
	["-"]   = { prec = 5, assoc = "left" },
	["*"]   = { prec = 6, assoc = "left" },
	["/"]   = { prec = 6, assoc = "left" },
}

function Parser:initialize(lexer)
	self.lexer = lexer
	self.tokens = {}
	for token in lexer:iter() do
		table.insert(self.tokens, token)
	end
	self.position = 1
	self.current = self.tokens[self.position]
end

function Parser:advance()
	self.position = self.position + 1
	self.current = self.tokens[self.position]
end

function Parser:peek()
	return self.tokens[self.position + 1]
end

function Parser:expect(type)
	if self.current and self.current.type == type then
		local token = self.current
		self:advance()
		return token
	else
		error(string.format("Expected token '%s' but got '%s' at line %d col %d",
			type, self.current and self.current.type or "EOF",
			self.current and self.current.line or -1,
			self.current and self.current.col or -1))
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
		table.insert(nodes, self:parse_statement())
	end
	return self:node("Program", { body = nodes })
end

function Parser:parse_let()
	self:expect("LET")
	local nameTok = self:expect("IDENTIFIER")
	local varType
	if self.current.type == "COLON" then
		self:advance()
		varType = self:expect("IDENTIFIER").value
	end
	local value
	if self.current.type == "ASSIGN" then
		self:advance()
		local expr = self:parse_expression()
		value = expr
	end
	self:expect("SEMICOLON")
	return self:node("VariableDeclaration", {
		name = nameTok.value,
		varType = varType,
		value = value,
		line = nameTok.line,
		column = nameTok.column
	})
end

function Parser:parse_return()
	self:expect("RETURN")
	local value
	if self.current and self.current.type ~= "END" and self.current.type ~= "ELSE" and self.current.type ~= "CATCH" and self.current.type ~= "FINALLY" then
		value = self:parse_expression()
	end
	self:expect("SEMICOLON")
	return self:node("ReturnStatement", { value = value })
end

function Parser:parse_class()
	self:expect("CLASS")
	local name = self:expect("IDENTIFIER").value

	local typeParams = nil
	if self.current and self.current.type == "OPERATOR" and self.current.value == "<" then
		self:advance()
		typeParams = {}
		while self.current and not (self.current.type == "OPERATOR" and self.current.value == ">") do
			local paramName = self:expect("IDENTIFIER").value
			table.insert(typeParams, paramName)
			if self.current.type == "COMMA" then
				self:advance()
			end
		end
		self:expect("OPERATOR") -- '>'
	end

	local superclass
	if self.current and self.current.type == "EXTENDS" then
		self:advance()
		superclass = self:expect("IDENTIFIER").value
	end
	local members = {}
	while self.current and self.current.type ~= "END" do
		if self.current.type == "FUNCTION" then
			table.insert(members, self:parse_function(true))
		elseif self.current.type == "LET" then
			local fld = self:parse_let()
			if fld.value == nil then
				table.insert(members, self:node("FieldDeclaration", fld))
			else
				table.insert(members, fld)
			end
		else
			error("Unexpected class member: " .. self.current.type)
		end
	end
	self:expect("END")
	return self:node("ClassDeclaration", {
		name = name,
		typeParams = typeParams,
		superclass = superclass,
		members = members
	})
end

function Parser:parse_statement()
	local t = self.current.type
	if t == "CLASS" then
		return self:parse_class()
	elseif t == "FUNCTION" then
		return self:parse_function(false)
	elseif t == "RETURN" then
		return self:parse_return()
	elseif t == "IF" then
		return self:parse_if()
	elseif t == "WHILE" then
		return self:parse_while()
	elseif t == "FOR" then
		return self:parse_for()
	elseif t == "TRY" then
		return self:parse_try()
	elseif t == "LET" then
		return self:parse_let()
	else
		return self:parse_expression_statement()
	end
end

function Parser:parse_function(isMethod)
	self:expect("FUNCTION")
	local name = self:expect("IDENTIFIER").value
	self:expect("PARENTHESIS") -- '('
	local params = self:parse_parameters()
	self:expect("PARENTHESIS") -- ')'
	local returnType
	if self.current and self.current.type == "COLON" then
		self:advance()
		returnType = self:expect("IDENTIFIER").value
	end
	local body = {}
	while self.current and self.current.type ~= "END" do
		table.insert(body, self:parse_statement())
	end
	self:expect("END")
	return self:node("FunctionDeclaration",
		{ name = name, params = params, returnType = returnType, body = body, isMethod = isMethod })
end

function Parser:parse_parameters()
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
			if self.current.type == "COMMA" then self:advance() end
		else
			break
		end
	end
	return params
end

function Parser:parse_if()
	self:expect("IF")
	local condition = self:parse_expression()
	self:expect("THEN")

	local then_body = {}
	while self.current and self.current.type ~= "ELSE" and self.current.type ~= "ELSEIF" and self.current.type ~= "END" do
		table.insert(then_body, self:parse_statement())
	end

	local elseif_branches = {}
	while self.current and self.current.type == "ELSEIF" do
		self:advance()
		local elseif_condition = self:parse_expression()
		self:expect("THEN")
		local elseif_body = {}
		while self.current and self.current.type ~= "ELSEIF" and self.current.type ~= "ELSE" and self.current.type ~= "END" do
			table.insert(elseif_body, self:parse_statement())
		end
		table.insert(elseif_branches, {
			condition = elseif_condition,
			body = elseif_body
		})
	end

	local else_body = nil
	if self.current and self.current.type == "ELSE" then
		self:advance()
		else_body = {}
		while self.current and self.current.type ~= "END" do
			table.insert(else_body, self:parse_statement())
		end
	end

	self:expect("END")
	return self:node("IfStatement", {
		condition = condition,
		then_body = then_body,
		elseif_branches = elseif_branches,
		else_body = else_body
	})
end

function Parser:parse_for()
	self:expect("FOR")
	local var = self:parse_let()
	if not var or var.kind ~= "VariableDeclaration" then
		error("Expected variable declaration in for loop")
	end
	self:expect("COMMA")
	local stop = self:parse_expression()
	local step = nil
	if self.current and self.current.type == "COMMA" then
		self:advance()
		step = self:parse_expression()
	end
	self:expect("DO")

	local body = {}
	while self.current and self.current.type ~= "END" do
		table.insert(body, self:parse_statement())
	end

	self:expect("END")
	return self:node("ForStatement", {
		var = var,
		stop = stop,
		step = step,
		body = body
	})
end

function Parser:parse_while()
	self:expect("WHILE")
	local cond = self:parse_expression()
	self:expect("DO")

	local body = {}
	while self.current and self.current.type ~= "END" do
		table.insert(body, self:parse_statement())
	end

	self:expect("END")
	return self:node("WhileStatement", {
		condition = cond,
		body = body
	})
end

function Parser:parse_try()
	self:expect("TRY")
	local tryBlock = {}
	while self.current and self.current.type ~= "CATCH" and self.current.type ~= "FINALLY" and self.current.type ~= "END" do
		table.insert(tryBlock, self:parse_statement())
	end

	local catchBlock = nil
	local catchVar = nil
	if self.current and self.current.type == "CATCH" then
		self:advance()
		catchVar = self:expect("IDENTIFIER").value
		local cb = {}
		while self.current and self.current.type ~= "FINALLY" and self.current.type ~= "END" do
			table.insert(cb, self:parse_statement())
		end
		catchBlock = { param = catchVar, body = cb }
	end

	local finallyBlock = nil
	if self.current and self.current.type == "FINALLY" then
		self:advance()
		local fb = {}
		while self.current and self.current.type ~= "END" do
			table.insert(fb, self:parse_statement())
		end
		finallyBlock = fb
	end

	self:expect("END")
	return self:node("TryStatement", {
		tryBlock = tryBlock,
		catchBlock = catchBlock,
		finallyBlock = finallyBlock
	})
end

function Parser:parse_expression_statement()
	local expr = self:parse_expression()
	if self.current and self.current.type == "ASSIGN" then
		self:advance()
		local value = self:parse_expression()
		self:expect("SEMICOLON")
		return self:node("AssignmentStatement", {
			target = expr,
			value = value
		})
	else
		self:expect("SEMICOLON")
		return self:node("ExpressionStatement", { expression = expr })
	end
end

function Parser:parse_expression()
	return self:parse_binary(0)
end

function Parser:parse_binary(minPrec)
	local left = self:parse_unary()
	while true do
		local tok = self.current
		if not tok then break end
		local op = tok.value
		local info = precedences[op]
		if not info or info.prec < minPrec then break end
		self:advance()
		local nextMin = info.prec + ((info.assoc == "left") and 1 or 0)
		local right = self:parse_binary(nextMin)
		left = self:node("BinaryExpression", {
			operator = op,
			left = left,
			right = right,
			line = op.line,
			column = op.column
		})
	end
	return left
end

function Parser:parse_unary()
	if self.current.type == "NOT" or (self.current.type == "OPERATOR" and self.current.value == "-") then
		local op = self.current.value
		self:advance()
		local expr = self:parse_unary()
		return self:node("UnaryExpression", { operator = op, argument = expr })
	end
	return self:parse_call()
end

function Parser:parse_call()
	local expr = self:parse_primary()
	while self.current and self.current.type == "PARENTHESIS" and self.current.value == "(" do
		-- function call
		self:advance()
		local args = {}
		while self.current and not (self.current.type == "PARENTHESIS" and self.current.value == ")") do
			table.insert(args, self:parse_expression())
			if self.current.type == "COMMA" then self:advance() end
		end
		self:expect("PARENTHESIS") -- ')'
		expr = self:node("CallExpression", {
			callee = expr,
			arguments = args,
			line = expr.line
		})
	end
	return expr
end

function Parser:parse_primary()
	local t = self.current
	if not t then error("Unexpected EOF in expression") end
	if t.type == "IDENTIFIER" or t.type == 'SELF' then
		self:advance()
		local expr = self:node("Identifier", {
			name = t.value,
			line = t.line
		})

		-- SUPPORT: chain of dot accesses
		while self.current and self.current.type == "DOT" do
			self:advance()
			local field = self:expect("IDENTIFIER")
			expr = self:node("FieldAccess", {
				object = expr,
				field = field.value,
				line = field.line
			})
		end

		return expr
	elseif t.type == "NEW" then
		self:advance()
		local call = self:parse_call()
		return self:node("NewInstance", {
			call = call,
			line = t.line
		})
	elseif t.type == "NUMBER" then
		self:advance()
		return self:node("NumberLiteral", {
			value = tonumber(t.value),
			line = t.line
		})
	elseif t.type == "STRING" then
		self:advance()
		return self:node("StringLiteral", {
			value = t.value,
			line = t.line
		})
	elseif t.type == "PARENTHESIS" and t.value == "(" then
		self:advance()
		local e = self:parse_expression()
		self:expect("PARENTHESIS")
		return e
	elseif t.type == 'FALSE' or t.type == 'TRUE' then
		self:advance()
		return self:node("BooleanLiteral", {
			value = t.value,
			line = t.line
		})
	else
		error("Unexpected token in expression: " .. t.type)
	end
end

return Parser
