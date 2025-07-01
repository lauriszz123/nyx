local class = require("middleclass")
local Scope = require("src.nyx.scope")
local AST = require("src.nyx.ast")

---@class Compiler
local Compiler = class("Compiler")

function Compiler:initialize()
	self.code = { "" }
	self.nextLabel = 0
	self.functions = {}
	self.structs = {}
	self.strings = {}
	self.currentFunction = nil

	---@type Scope
	self.scope = Scope()
	self.scope:declareFunction(
		"poke",
		{
			{ name = "pointer", type = "ptr" },
			{ name = "value", type = "u8" },
		},
		"nil",
		function(self)
			self:emitComment("Store value at the pointer")
			self:emit("PLA")
			self:emit("PLP", "#1")
			self:emit("STA", "(HL)")
		end
	)

	self.scope:declareFunction(
		"peek",
		{
			{ name = "pointer", type = "ptr" },
		},
		"u8",
		function(self)
			self:emitComment("Return value at pointer")
			self:emit("PLP", "#1")
			self:emit("LDA", "(HL)")
		end
	)

	self.scope:declareFunction(
		"peek",
		{
			{ name = "pointer", type = "str" },
			{ name = "offset", type = "u8" },
		},
		"u8",
		function(c)
			c:emitComment("Return value at string pointer + offset")
			c:emit("PLA")
			c:emit("PLP", "#1")
			c:emit("ADDHL")
			c:emit("LDA", "(HL)")
		end
	)

	self.visitor = require("src.nyx.compiler.visitor")
end

function Compiler:emit(op, ...)
	local instr = op .. " " .. table.concat({ ... }, ", ") .. "\n"
	self.code[#self.code] = self.code[#self.code] .. instr
end

---@param comment string Comment in the assembly file
function Compiler:emitComment(comment)
	comment = "; " .. comment
	self:emit(comment)
end

function Compiler:pushCode()
	table.insert(self.code, "")
end

function Compiler:popCode()
	return table.remove(self.code, #self.code)
end

function Compiler:newLabel(prefix)
	if prefix == nil then
		self.nextLabel = self.nextLabel + 1
		prefix = tostring(self.nextLabel)
	end
	return "L" .. prefix .. ":"
end

function Compiler:newString(str)
	local strname = "str_" .. #self.strings
	table.insert(self.strings, {
		name = strname,
		value = str,
	})
	return strname
end

function Compiler:generateFunctions()
	self:emitComment("Function Memory Space")
	self:emit("")
	local code = self.code[#self.code]
	code = code .. "\n"
	for _, fn in ipairs(self.functions) do
		code = code .. fn .. "\n"
	end
	code = code .. "\n"
	self.code[#self.code] = code
end

function Compiler:generate(ast)
	assert(ast.kind == "Program", "AST must be a Program")
	AST.visit(self, ast)

	return self.code[#self.code]
end

return Compiler
