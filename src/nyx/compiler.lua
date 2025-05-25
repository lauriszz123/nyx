-- compiler.lua
local class = require("middleclass")
local Scope = require("src.nyx.scope")
local AST   = require("src.nyx.ast")

local Compiler = class("Compiler")

-- Initialize compiler state
function Compiler:initialize(ramAddr)
	-- emitted instructions: each is {op, args}
	self.code       = ""
	-- label → instruction index
	self.functions = {}
	-- label index for new labels
	self.nextLabel  = 0
	-- variable name → memory address
	self.scope = Scope()
	-- next RAM address for globals
	self.ramAddr   = ramAddr or 0x2000
end

function Compiler:getCode()
	return self.code
end

function Compiler:setCode(oldCode)
	self.code = oldCode
end

-- Emit an instruction, return its position
function Compiler:emit(op, ...)
	self.code = self.code .. op .. " " .. table.concat({...}, ", ") .. "\n"
end

-- Generate a fresh label
function Compiler:newLabel(prefix)
	if prefix == nil then
		self.nextLabel = self.nextLabel + 1
		prefix = prefix .. tostring(self.nextLabel)
	end
	return prefix
end

-- Place a label at the current code position
function Compiler:placeLabel(label)
	self.labels[label] = #self.code + 1
end

-- Entry point: compile a Program AST node
function Compiler:compile(ast)
	assert(ast.kind == "Program", "AST must be a Program")
	AST.visit(ast, self.visitor, self)
	self:emit("HLT") -- end of program

	for _, fn in ipairs(self.functions) do
		self.code = self.code .. fn .. "\n"
	end

	return self.code
end

-- Visitor table mapping AST node kinds to compile methods
Compiler.visitor = {
	Program = function(node, self)
		for _, stmt in ipairs(node.body) do
			AST.visit(stmt, self.visitor, self)
		end
	end,

	VariableDeclaration = function(node, self)
		AST.visit(node.value, self.visitor, self)
		if self.scope.isLocalScope then
			self.scope:declareLocal(node.name, node.varType)
			self:emit("PHA")
		else
			-- store global variable
			self.scope:declare(node.name, node.varType, self.ramAddr)
			self:emit("STA ($" .. string.format("%x", self.ramAddr ) .. ")")
			self.ramAddr = self.ramAddr + 1
		end
	end,

	AssignmentStatement = function (node, self)
		AST.visit(node.value, self.visitor, self)
		if self.scope.isLocalScope then
			local var = self.scope:fetch(node.target.name)
			self:emit("SET", '#' .. var.index)
		else
			print("TODO: global assignment")
		end
	end,

	FunctionDeclaration = function(node, self)
		local fnName = self:newLabel(node.name)

		local code = self:getCode()
		self:setCode("")

		self:emit(fnName .. ":")
		self:emit("PHP")
		self:emit("SBP")

		-- create a new scope for the function
		self.scope = Scope(self.scope)
		self.scope:isLocal(true)

		-- parameters
		for i, param in ipairs(node.params) do
			self.scope:declareLocal(param.name, param.varType, -(#node.params - (i - 1)))
		end

		-- compile body
		for _, stmt in ipairs(node.body) do
			AST.visit(stmt, self.visitor, self)
		end

		-- return (drops into caller)
		self:emit("PLP") -- pop base pointer
		self:emit("RET")

		-- restore scope
		self.scope = self.scope.parent

		-- restore the program code
		local fn = self:getCode()
		self:setCode(code)
		table.insert(self.functions, fn)
	end,

	CallExpression = function(node, self)
		-- push args in order
		for _, arg in ipairs(node.arguments) do
			AST.visit(arg, self.visitor, self)
			self:emit("PHA")
		end
		-- call function label
		local fname = assert(node.callee.name, "Call target must be identifier")
		self:emit("CALL (" .. fname .. ")")
		-- clean up args (if your VM needs manual cleanup)
		for _ = 1, #node.arguments do
			self:emit("PLB")
		end
	end,

	ExpressionStatement = function(node, self)
		AST.visit(node.expression, self.visitor, self)
	end,

	NumberLiteral = function(node, self)
		self:emit("LDA", '#' .. node.value)
	end,

	StringLiteral = function(node, self)
		-- stub: load address of string literal (not implemented)
		error("StringLiteral compilation not implemented")
	end,

	Identifier = function(node, self)
		local var = self.scope:fetch(node.name)
		if var.isLocal then
			-- load local variable into A
			if var.index < 0 then
				-- negative index means local variable
				self:emit("GETN #" .. string.format("%d", math.abs(var.index) + 4))
			else
				-- positive index means argument
				self:emit("GET #" .. string.format("%d", var.index))
			end
		else
			-- TODO: implement this logic for globals
			self:emit("LDA ($" .. string.format("%x", var.address ) .. ")")
		end
	end,

	FieldAccess = function(node, self)
		-- compile object address into A
		AST.visit(node.object, self.visitor, self)
		-- assume A holds base pointer; move into H/L
		self:emit("MOV_HL_A") -- pseudo-instruction: HL = A
		-- load field offset (we'll assume offset 0 for stub)
		local offset = 0
		self:emit("ADD_HL_IMM", offset)
		self:emit("LD_A_HL") -- pseudo: A = [HL]
	end,

	BinaryExpression = function(node, self)
		-- compile left into A, push
		AST.visit(node.left, self.visitor, self)
		self:emit("PHA")
		-- compile right into A
		AST.visit(node.right, self.visitor, self)
		-- pop left into B
		self:emit("PLB")
		-- apply operator
		local op = node.operator
		if op == "+" then
			self:emit("ADD")
		elseif op == "-" then
			self:emit("SUB")
		elseif op == "*" then
			self:emit("MUL")
		elseif op == "/" then
			self:emit("DIV")
		elseif op == "==" then
			self:emit("CMP")
		else
			error("Unknown binary operator: " .. op)
		end
	end,

	UnaryExpression = function(node, self)
		AST.visit(node.argument, self.visitor, self)
		if node.operator == "-" then
			self:emit("NEG")
		elseif node.operator == "not" then
			self:emit("NOT")
		else
			error("Unknown unary operator: " .. node.operator)
		end
	end,

	IfStatement = function(node, self)
		-- compile condition in A
		AST.visit(node.condition, self.visitor, self)
		-- if zero jump to else or end

		-- then-body
		for _, stmt in ipairs(node.then_body) do
			AST.visit(stmt, self.visitor, self)
		end

		-- else/elseif
		if node.elseif_branches then
			for _, eb in ipairs(node.elseif_branches) do
				-- compile elseif condition
				print("elseif condition")
				AST.visit(eb.condition, self.visitor, self)
			end
		end
		if node.else_body then
			print("else body")
			for _, stmt in ipairs(node.else_body) do
				AST.visit(stmt, self.visitor, self)
			end
		end
	end,

--[[	WhileStatement = function(node, self)
		local startLabel = self:newLabel("while")
		local endLabel   = self:newLabel("wend")
		self:placeLabel(startLabel)
		AST.visit(node.condition, self.visitor, self)
		local pos = self:emit("JZ", 0)
		self:patchJump(pos, endLabel)
		for _, stmt in ipairs(node.body) do
			AST.visit(stmt, self.visitor, self)
		end
		self:emit("JMP", 0)
		self:patchJump(#self.code, startLabel)
		self:placeLabel(endLabel)
	end,

	ReturnStatement = function(node, self)
		if node.value then
			AST.visit(node.value, self.visitor, self)
		end
		self:emit("PLP")
		self:emit("RET")
	end, --]]
}

return Compiler