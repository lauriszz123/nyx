local class = require("middleclass")
local Scope = require("src.nyx.scope")
local AST = require("src.nyx.ast")

local Compiler = class("Compiler")

function Compiler:initialize()
	self.code = ""
	self.nextLabel = 0
	self.functions = {}
	self.structs = {}

	self.scope = Scope()
	self.scope:declareFunction(
		"poke",
		{
			{ name = "pointer", type = "ptr" },
			{ name = "value", type = "u8" },
		},
		"nil",
		function(self)
			self:emit("PLA")
			self:emit("PLP", "#" .. 0x1)
			self:emit("STA", "(HL)")
		end
	)

	self.visitor = require("src.nyx.compiler.visitor")
end

function Compiler:emit(op, ...)
	self.code = self.code .. op .. " " .. table.concat({ ... }, ", ") .. "\n"
end

function Compiler:newLabel(prefix)
	if prefix == nil then
		self.nextLabel = self.nextLabel + 1
		prefix = prefix .. tostring(self.nextLabel)
	end
	return "L" .. prefix
end

function Compiler:generate(ast)
	assert(ast.kind == "Program", "AST must be a Program")
	AST.visit(self, ast)

	return self.code
end

return Compiler
