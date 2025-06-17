local class = require("middleclass")
local AST = require("src.nyx.ast")

local Compiler = class("Compiler")

function Compiler:initialize()
	self.code = ""
	self.nextLabel = 0
	self.functions = {}
	self.structs = {}

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
	self:emit("HLT")
end

return Compiler
