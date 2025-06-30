local class = require("middleclass")

local Memory = require("src.util.memory")
local Lexer = require("src.nyx.lexer")

local function reverseList(t)
	local reversed = {}
	local n = #t               -- Get the length of the table
	for i = 1, n do
		reversed[i] = t[n - i + 1] -- Fill the reversed table
	end
	return reversed
end

local IR_CODES = {
	const_u8 = {
		argc = 1,
		process = function(self, u8)
			self:push_u8(u8)
		end,
	},
	const_u16 = {
		argc = 1,
		process = function(self, u16)
			local hi = bit.rshift(u16, 8)
			local lo = bit.band(u16, 0xFF)
			self:push_u8(lo)
			self:push_u8(hi)
		end,
	},
	define_global = {
		argc = 2,
		process = function(self, name, type)
			if type == "u8" then
				self.memory:write(self.varmem, self:pop_u8())
				self.globals[name] = {
					type = type,
					pointer = self.varmem,
				}
				self.varmem = self.varmem + 1
			end
		end,
	},
	load_global_u8 = {
		argc = 1,
		process = function(self, name)
			local var = self.globals[name]

			self:push_u8(self.memory:read(var.pointer))
		end,
	},
	set_global = {
		argc = 1,
		process = function(self, name)
			local var = self.globals[name]
			local value = self:pop_u8()

			self.memory:write(var.pointer, value)
		end,
	},
	add = {
		argc = 0,
		process = function(self)
			local b = self:pop_u8()
			self:push_u8(self:pop_u8() + b)
		end,
	},
	system_call = {
		argc = 2,
		process = function(self, name, argc)
			local syscall = self.sys_calls[name]
			if syscall then
				local args = {}
				for i = #syscall.args, 1, -1 do
					local arg = syscall.args[i]
					if arg == "u8" then
						table.insert(args, self:pop_u8())
					elseif arg == "u16" then
						local hi = self:pop_u8()
						local lo = self:pop_u8()
						table.insert(args, bit.bor(bit.lshift(hi, 8), lo))
					end
				end
				args = reverseList(args)
				syscall.call(self, unpack(args))
			end
		end,
	},
	halt = {
		argc = 0,
		process = function(self)
			self.halted = true
		end,
	},
}

---@class Interpreter
local Interpreter = class("Interpreter")

function Interpreter:initialize()
	self.irList = {}
	---@type Memory
	self.memory = Memory()
	self.sp = 0x1FF
	self.varmem = 0x2000
	self.globals = {}
	self.sys_calls = {
		poke = {
			args = { "u16", "u8" },
			call = function(intr, pointer, value)
				intr.memory:write(pointer, value)
			end,
		},
	}

	self.halted = false
end

function Interpreter:push_u8(u8)
	self.memory:write(self.sp, u8)
	self.sp = self.sp - 1
end

function Interpreter:pop_u8()
	self.sp = self.sp + 1
	return self.memory:read(self.sp)
end

---@param source string IR Code Source
function Interpreter:setupLexer(source)
	local lexer = Lexer(source, true)
	self.tokens = {}
	for token in lexer:iter() do
		table.insert(self.tokens, token)
	end

	self.position = 1
	self.current = self.tokens[self.position]
end

function Interpreter:advance()
	self.position = self.position + 1
	self.current = self.tokens[self.position]
	return self.current
end

-- Peek at the next token without advancing
function Interpreter:peek(offset)
	offset = offset or 0
	return self.tokens[self.position + offset]
end

function Interpreter:tokenize(source)
	self:setupLexer(source)
	while self.current do
		local currType = self:peek().type
		if currType == "IDENTIFIER" then
			local name = self:peek().value
			self:advance()

			local ir = IR_CODES[name]
			if not ir then
				error("Unknown IR: " .. name)
			end
			local args = {}

			for i = 1, ir.argc do
				if self.current.type == "IDENTIFIER" or self.current.type == "NUMBER" then
					table.insert(args, self.current.value)
					self:advance()
				else
					error("Unknown arg type: " .. self.current.type)
				end

				if i < ir.argc then
					if self.current.type ~= "COMMA" then
						error("Expected a comma!")
					else
						self:advance()
					end
				end
			end

			table.insert(self.irList, {
				name = name,
				args = args,
			})
		else
			error("Unknown type: " .. currType)
		end
	end
end

function Interpreter:run()
	local pc = 1
	while pc < #self.irList and not self.halted do
		local instr = self.irList[pc]
		if IR_CODES[instr.name] then
			if IR_CODES[instr.name].process then
				local ok, err = pcall(IR_CODES[instr.name].process, self, unpack(instr.args))
				if not ok then
					error(err)
				end
			else
				print("TODO:", "Implement " .. instr.name .. " process function!")
			end
		else
			print(instr.name, "doesnt exist!")
		end
		pc = pc + 1
	end
end

return Interpreter
