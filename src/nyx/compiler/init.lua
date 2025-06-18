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
	local instr = op .. " " .. table.concat({ ... }, ", ") .. "\n"
	self.code[#self.code] = self.code[#self.code] .. instr
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
		prefix = prefix .. tostring(self.nextLabel)
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
	local code = self.code[#self.code]
	code = code .. "\n"
	for _, fn in ipairs(self.functions) do
		code = code .. fn .. "\n"
	end
	self.code[#self.code] = code
end

function Compiler:generateStrings()
	for _, str in ipairs(self.strings) do
		self:emit(str.name .. ":")
		for i = 1, #str.value do
			local chr = str.value:sub(i, i)
			self:emit("DB", "#" .. string.byte(chr))
		end
	end
	self:emit("DB", 0)
end

function Compiler:generate(ast)
	assert(ast.kind == "Program", "AST must be a Program")
	AST.visit(self, ast)

	return self.code[#self.code]
end

return Compiler
