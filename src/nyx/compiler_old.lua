-- compiler.lua
local class = require("middleclass")
local AST = require("src.nyx.ast")

local Compiler = class("Compiler")

-- Initialize compiler state
function Compiler:initialize(ramAddr)
	-- emitted instructions: each is {op, args}
	self.code = ""
	-- label → instruction index
	self.functions = {}
	-- label index for new labels
	self.nextLabel = 0
	-- variable name → memory address
	self.scope = Scope()
	-- next RAM address for globals
	self.ramAddr = ramAddr or 0x2000
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
