local class = require("middleclass")

local Memory = require("src.util.memory")
local Lexer = require("src.nyx.lexer")

local function reverseList(t)
	local reversed = {}
	local n = #t -- Get the length of the table
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
			elseif type == "u16" then
				self.memory:write(self.varmem, self:pop_u8())
				self.memory:write(self.varmem + 1, self:pop_u8())
				self.globals[name] = {
					type = type,
					pointer = self.varmem,
				}
				self.varmem = self.varmem + 2
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

	load_global_u16 = {
		argc = 1,
		process = function(self, name)
			local var = self.globals[name]
			local hi = self.memory:read(var.pointer)
			local lo = self.memory:read(var.pointer + 1)
			self:push_u8(lo)
			self:push_u8(hi)
			print(lo, hi)
		end,
	},

	load_local_u8 = {
		argc = 1,
		process = function(self, index)
			local val = self.memory:read(self.bp - index)
			print("load_local_u8", val)
			self:push_u8(val)
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

	call = {
		argc = 1,
		process = function(self, name)
			local hi = bit.rshift(self.pc, 8)
			local lo = bit.band(self.pc, 0xFF)
			self:push_u8(lo)
			self:push_u8(hi)
			self.pc = self.functions[name].pointer
			hi = bit.rshift(self.bp, 8)
			lo = bit.band(self.bp, 0xFF)
			self:push_u8(lo)
			self:push_u8(hi)
			self.bp = self.sp
		end,
	},

	["return"] = {
		argc = 0,
		process = function(self)
			local hi = self:pop_u8()
			local lo = self:pop_u8()
			self.bp = bit.bor(bit.lshift(hi, 8), lo)
			hi = self:pop_u8()
			lo = self:pop_u8()
			self.pc = bit.bor(bit.lshift(hi, 8), lo)
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
			else
				print("NO SYS CALL")
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
	self.bp = self.sp
	self.varmem = 0x2000
	self.globals = {}
	self.sys_calls = {
		poke_1 = {
			args = { "u16", "u8" },
			call = function(intr, pointer, value)
				intr.memory:write(pointer, value)
				print("pointer", string.format("0x%x", pointer))
			end,
		},
	}
	self.labels = {}
	self.functions = {}

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

function Interpreter:atom()
	local val = self.current.value
	if self.current.type == "IDENTIFIER" then
		self:advance()
		if self.current.type == "COLON" then
			self:advance()
			local t = self.current.value
			self:advance()
			return {
				kind = "NameType",
				name = val,
				type = t,
			}
		else
			return val
		end
	elseif self.current.type == "OPERATOR" and val == "-" then
		self:advance()
		local ret = -self.current.value
		self:advance()
		return ret
	else
		self:advance()
		return val
	end
end

function Interpreter:tokenize(source)
	self:setupLexer(source)
	local pc = 1
	while self.current do
		local currType = self:peek().type
		if currType == "IDENTIFIER" or currType == "RETURN" then
			local name = self:peek().value
			self:advance()

			if self.current and self.current.type == "COLON" then
				self:advance()
				self.labels[name] = pc
			else
				if name == "function" then
					local args = {}
					name = self.current.value
					if self:advance().type == "COMMA" then
						self:advance()
					end

					while self.current do
						table.insert(args, self:atom())
						if self.current.type ~= "COMMA" then
							break
						end
						self:advance()
					end

					self.functions[name] = {
						argc = #args,
						args = args,
						pointer = pc + 1,
					}
				else
					local ir = IR_CODES[name]
					if not ir then
						error("Unknown IR: " .. name .. " line: " .. self.current.line)
					end
					local args = {}

					for i = 1, ir.argc do
						table.insert(args, self:atom())

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
					pc = pc + 1
				end
			end
		else
			error("Unknown type: " .. currType)
		end
	end
end

function Interpreter:run()
	self.pc = 1
	while self.pc < #self.irList and not self.halted do
		local instr = self.irList[self.pc]
		if not instr then
			return
		end
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
		self.pc = self.pc + 1
	end
end

return Interpreter
