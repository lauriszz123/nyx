local class = require("middleclass")

local PluginManager = require("src.vm.pluginManager")
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
			if self.globals["!" .. u16] then
				u16 = self.globals["!" .. u16].pointer
			elseif self.globals[u16] then
				u16 = self.globals[u16].pointer
			end
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
			else
				error("WTF")
			end
		end,
	},

	define_const = {
		argc = 2,
		process = function(self, name, type)
			if type == "u8" then
				self.memory:write(self.varmem, self:pop_u8())
				self.globals[name] = {
					isConst = true,
					type = type,
					pointer = self.varmem,
				}
				self.varmem = self.varmem + 1
			elseif type == "u16" then
				self.memory:write(self.varmem, self:pop_u8())
				self.memory:write(self.varmem + 1, self:pop_u8())
				self.globals[name] = {
					isConst = true,
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
		end,
	},

	load_local_u8 = {
		argc = 1,
		process = function(self, index)
			local val = self.memory:read(self.bp - index)
			self:push_u8(val)
		end,
	},

	load_local_u16 = {
		argc = 1,
		process = function(self, index)
			local lo = self.memory:read(self.bp - index)
			local hi = self.memory:read(self.bp - (index + 1))
			self:push_u8(lo)
			self:push_u8(hi)
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

	set_local_u8 = {
		argc = 1,
		process = function(self, index)
			local val = self:pop_u8()
			self.memory:write(self.bp - index, val)
		end,
	},

	pop_u8 = {
		argc = 0,
		process = function(self)
			self:pop_u8()
		end,
	},

	pop_fncall = {
		argc = 1,
		process = function(self, size)
			for _ = 1, size do
				self:pop_u8()
			end
			if self.returnValue then
				self:push_u8(self.returnValue)
				self.returnValue = nil
			end
		end,
	},

	add_u8 = {
		argc = 0,
		process = function(self)
			local b = self:pop_u8()
			self:push_u8(self:pop_u8() + b)
		end,
	},

	sub_u8 = {
		argc = 0,
		process = function(self)
			local b = self:pop_u8()
			self:push_u8(self:pop_u8() - b)
		end,
	},

	mul_u8 = {
		argc = 0,
		process = function(self)
			local b = self:pop_u8()
			self:push_u8(self:pop_u8() * b)
		end,
	},

	div_u8 = {
		argc = 0,
		process = function(self)
			local b = self:pop_u8()
			self:push_u8(math.floor(self:pop_u8() / b))
		end,
	},

	u8_to_u16 = {
		argc = 0,
		process = function(self)
			self:push_u8(self:pop_u8())
			self:push(0x00)
		end,
	},

	u16_to_u8 = {
		argc = 0,
		process = function(self)
			self:pop_u8()
			self:push_u8(self:pop_u8())
		end,
	},

	add_u16 = {
		argc = 0,
		process = function(self)
			local hib = self:pop_u8()
			local lob = self:pop_u8()
			local b = bit.bor(bit.lshift(hib, 8), lob)
			local hi = self:pop_u8()
			local lo = self:pop_u8()
			local u16 = bit.bor(bit.lshift(hi, 8), lo) + b
			hi = bit.band(bit.rshift(u16, 8), 0xFF)
			lo = bit.band(u16, 0xFF)
			self:push_u8(lo)
			self:push_u8(hi)
		end,
	},

	sub_u16 = {
		argc = 0,
		process = function(self)
			local hib = self:pop_u8()
			local lob = self:pop_u8()
			local b = bit.bor(bit.lshift(hib, 8), lob)
			local hi = self:pop_u8()
			local lo = self:pop_u8()
			local u16 = bit.bor(bit.lshift(hi, 8), lo) - b
			hi = bit.band(bit.rshift(u16, 8), 0xFF)
			lo = bit.band(u16, 0xFF)
			self:push_u8(lo)
			self:push_u8(hi)
		end,
	},

	mul_u16 = {
		argc = 0,
		process = function(self)
			local hib = self:pop_u8()
			local lob = self:pop_u8()
			local b = bit.bor(bit.lshift(hib, 8), lob)
			local hi = self:pop_u8()
			local lo = self:pop_u8()
			local u16 = bit.bor(bit.lshift(hi, 8), lo) * b
			hi = bit.band(bit.rshift(u16, 8), 0xFF)
			lo = bit.band(u16, 0xFF)
			self:push_u8(lo)
			self:push_u8(hi)
		end,
	},

	div_u16 = {
		argc = 0,
		process = function(self)
			local hib = self:pop_u8()
			local lob = self:pop_u8()
			local b = bit.bor(bit.lshift(hib, 8), lob)
			local hi = self:pop_u8()
			local lo = self:pop_u8()
			local u16 = math.floor(bit.bor(bit.lshift(hi, 8), lo) / b)
			hi = bit.band(bit.rshift(u16, 8), 0xFF)
			lo = bit.band(u16, 0xFF)
			self:push_u8(lo)
			self:push_u8(hi)
		end,
	},

	call = {
		argc = 1,
		process = function(self, name)
			local hi = bit.rshift(self.pc, 8)
			local lo = bit.band(self.pc, 0xFF)
			self:push_u8(lo)
			self:push_u8(hi)
			hi = bit.rshift(self.bp, 8)
			lo = bit.band(self.bp, 0xFF)
			self:push_u8(lo)
			self:push_u8(hi)
			self.bp = self.sp
			self.pc = self.functions[name].pointer
		end,
	},

	set_return_value = {
		argc = 0,
		process = function(self)
			self.returnValue = self:pop_u8()
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

	cmp_eq = {
		argc = 0,
		process = function(self)
			local b = self:pop_u8()
			self:push_u8(self:pop_u8() == b and 1 or 0)
		end,
	},

	cmp_neq = {
		argc = 0,
		process = function(self)
			local b = self:pop_u8()
			self:push_u8(self:pop_u8() ~= b and 1 or 0)
		end,
	},

	cmp_lt = {
		argc = 0,
		process = function(self)
			local b = self:pop_u8()
			self:push_u8(self:pop_u8() < b and 1 or 0)
		end,
	},

	cmp_leq = {
		argc = 0,
		process = function(self)
			local b = self:pop_u8()
			self:push_u8(self:pop_u8() <= b and 1 or 0)
		end,
	},

	cmp_mt = {
		argc = 0,
		process = function(self)
			local b = self:pop_u8()
			self:push_u8(self:pop_u8() > b and 1 or 0)
		end,
	},

	cmp_meq = {
		argc = 0,
		process = function(self)
			local b = self:pop_u8()
			self:push_u8(self:pop_u8() >= b and 1 or 0)
		end,
	},

	jmp_z = {
		argc = 1,
		process = function(self, loc)
			if self.labels[loc] then
				loc = self.labels[loc]
			end
			local val = self:pop_u8()
			if val == 0 then
				self.pc = loc
			end
		end,
	},

	jump = {
		argc = 1,
		process = function(self, loc)
			if self.labels[loc] then
				loc = self.labels[loc]
			end
			self.pc = loc
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
	self.halted = false
	self.irList = {}
	self.sys_calls = {
		poke_1 = {
			args = { "u16", "u8" },
			call = function(intr, pointer, value)
				intr.memory:write(pointer, value)
			end,
		},
		poke_2 = {
			args = { "u16", "u16" },
			call = function(intr, pointer, value)
				local hi = bit.rshift(value, 8)
				local lo = bit.band(value, 0xFF)
				intr.memory:write(pointer, hi)
				intr.memory:write(pointer + 1, lo)
			end,
		},
		peek_1 = {
			args = { "u16" },
			call = function(intr, pointer)
				intr:push_u8(intr.memory:read(pointer))
			end,
		},
		peek_2 = {
			args = { "u16", "u8" },
			call = function(intr, pointer, offset)
				intr:push_u8(intr.memory:read(pointer + offset))
			end,
		},
	}

	self.labels = {}
	self.globals = {}
	self.functions = {}
	self.returnValue = nil

	---@type PluginManager
	self.pluginManager = PluginManager()
	---@type Memory
	self.memory = Memory(self.pluginManager)
	self.sp = 0x1FF
	self.bp = self.sp
	self.varmemstart = 0x2000
	self.varmem = self.varmemstart
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
	self.varmem = 0x2000
	while self.current do
		local currType = self:peek().type
		if currType == "IDENTIFIER" or currType == "RETURN" then
			local name = self:peek().value
			self:advance()

			if self.current and self.current.type == "COLON" then
				self:advance()
				self.labels[name] = #self.irList
			else
				if name == "function" then
					local args = {}
					local noargs = false
					name = self.current.value
					if self:advance().type == "COMMA" then
						self:advance()
					else
						noargs = true
					end

					while self.current and noargs == false do
						table.insert(args, self:atom())
						if self.current.type ~= "COMMA" then
							break
						end
						self:advance()
					end

					self.functions[name] = {
						argc = #args,
						args = args,
						pointer = #self.irList,
					}
				elseif name == "alloc_string" then
					name = self.current.value
					if self:advance().type == "COMMA" then
						self:advance()
					end
					local str = self.current.value
					self:advance()

					local start = self.varmem
					for i = 1, #str do
						local chr = str:sub(i, i):byte()
						self.memory:write(start + (i - 1), chr)
					end
					self.memory:write(start + #str, 0x00)
					self.globals["!" .. name] = {
						pointer = start,
					}
					self.varmem = self.varmem + #str + 1
				elseif name == "alloc_struct" then
					name = self.current.value
					if self:advance().type == "COMMA" then
						self:advance()
					end
					local size = self.current.value
					self:advance()

					local start = self.varmem
					for i = 1, size do
						self.memory:write(start + (i - 1), 0x00)
					end
					self.globals["!" .. name] = {
						pointer = start,
						size = size,
					}
					self.varmem = self.varmem + size
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
				end
			end
		else
			error("Unknown type: " .. currType)
		end
	end
	self.pc = 1
end

function Interpreter:run()
	self.pc = 1
	while self.pc <= #self.irList and not self.halted do
		self:step()
	end
end

function Interpreter:step()
	if self.pc > #self.irList then
		self.halted = true
		return
	end

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

return Interpreter
