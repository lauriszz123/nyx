local class = require("middleclass")

---@class CPU
local CPU = class("CPU")

-- Status flag masks
local FLAGS = {
	C = 0x01,
	Z = 0x02,
	I = 0x04,
	D = 0x08,
	B = 0x10,
	V = 0x20,
	N = 0x40,
}

function CPU:initialize(memory)
	-- Registers
	self.A = 0
	self.B = 0
	self.H = 0
	self.L = 0
	self.SP = 0x1FFF
	self.BP = 0x1FFF
	self.PC = 0x0000
	self.SR = FLAGS.I
	---@type Memory
	self.memory = memory
	self.halted = false
end

-- Reset CPU state
function CPU:reset()
	self.A = 0
	self.B = 0
	self.H = 0
	self.L = 0
	self.SP = 0x1FFF
	self.PC = bit.band(bit.lshift(self.memory:read(0xFFFE), 8), self.memory:read(0xFFFF))
	self.SR = FLAGS.I -- interrupts enabled by default
	self.halted = false
end

function CPU:setFlag(flag)
	self.SR = bit.bor(self.SR, flag)
end

function CPU:clearFlag(flag)
	self.SR = bit.band(self.SR, bit.bnot(flag))
end

function CPU:isFlagSet(flag)
	return bit.band(self.SR, flag) ~= 0
end

-- Fetch next byte
function CPU:fetch()
	local byte = self.memory:read(self.PC)
	self.PC = bit.band(self.PC + 1, 0xFFFF)
	return byte
end

-- Combine H and L
function CPU:getHL()
	local combined = bit.bor(bit.lshift(self.H, 8), self.L)
	return bit.band(combined, 0xFFFF)
end

function CPU:setHL(val)
	val = bit.band(val, 0xFFFF)
	self.H = bit.rshift(val, 8)
	self.L = bit.band(val, 0xFF)
end

function CPU:push(value)
	self.memory:write(self.SP, value)
	self.SP = bit.band(self.SP - 1, 0xFFFF)
end

-- Pop a byte from the stack
function CPU:pop()
	self.SP = bit.band(self.SP + 1, 0xFFFF)
	return self.memory:read(self.SP)
end

-- Execute one instruction, return cycles used
function CPU:step()
	local op = self:fetch()
	if op == 0x10 then -- LDA #imm8
		local imm = self:fetch()
		self.A = imm
		if self.A == 0 then
			self:setFlag(FLAGS.Z)
		end
		return 2
	elseif op == 0x11 then -- LDB #imm8
		local imm = self:fetch()
		self.B = imm
		if self.B == 0 then
			self:setFlag(FLAGS.Z)
		end
		return 2
	elseif op == 0x12 then -- LDHL #imm16
		local lo = self:fetch()
		local hi = self:fetch()
		self:setHL(bit.bor(bit.lshift(hi, 8), lo))
		return 3
	elseif op == 0x20 then -- LDA (HL)
		local addr = self:getHL()
		self.A = self.memory:read(addr)
		if self.A == 0 then
			self:setFlag(FLAGS.Z)
		end
		return 3
	elseif op == 0x21 then -- STA (HL)
		local addr = self:getHL()
		self.memory:write(addr, self.A)
		return 3
	elseif op == 0x22 then -- LDA (#imm16)
		local lo = self:fetch()
		local hi = self:fetch()
		local addr = bit.bor(bit.lshift(hi, 8), lo)
		self.A = self.memory:read(addr)
		if self.A == 0 then
			self:setFlag(FLAGS.Z)
		end
		return 4
	elseif op == 0x23 then -- STA (#imm16)
		local lo = self:fetch()
		local hi = self:fetch()
		local addr = bit.bor(bit.lshift(hi, 8), lo)
		self.memory:write(addr, self.A)
		return 4
	elseif op == 0x24 then -- SBP
		self.BP = self.SP
		return 1
	elseif op == 0x25 then -- STHL (#imm16)
		local lo = self:fetch()
		local hi = self:fetch()
		local addr = bit.bor(bit.lshift(hi, 8), lo)
		self.memory:write(addr, self.H)
		self.memory:write(addr + 1, self.L)
		return 7
	elseif op == 0x26 then -- LDHL (#imm16)
		local lo = self:fetch()
		local hi = self:fetch()
		local addr = bit.bor(bit.lshift(hi, 8), lo)
		self.H = self.memory:read(addr)
		self.L = self.memory:read(addr + 1)
		return 6
	elseif op == 0x30 then -- ADD A, B
		local result = self.A + self.B
		if result > 0xFF then
			self:setFlag(FLAGS.C)
		end
		self.A = bit.band(result, 0xFF)
		if self.A == 0 then
			self:setFlag(FLAGS.Z)
		end
		return 1
	elseif op == 0x31 then -- SUB A, B
		local result = self.A - self.B
		if result >= 0 then
			self:setFlag(FLAGS.C)
		end
		self.A = bit.band(result, 0xFF)
		if self.A == 0 then
			self:setFlag(FLAGS.Z)
		end
		return 1
	elseif op == 0x32 then -- MUL A, B
		local result = self.A * self.B
		if result > 0xFF then
			self:setFlag(FLAGS.C)
		end
		self.A = bit.band(result, 0xFF)
		if self.A == 0 then
			self:setFlag(FLAGS.Z)
		end
		return 1
	elseif op == 0x33 then -- DIV A, B
		if self.B == 0 then
			self:setFlag(FLAGS.C) -- Division by zero error
			self.A = 0
		else
			self:clearFlag(FLAGS.C)
			self.A = math.floor(self.A / self.B)
		end
		if self.A == 0 then
			self:setFlag(FLAGS.Z)
		end
		return 1
	elseif op == 0x40 then -- INC HL
		self:setHL(self:getHL() + 1)
		return 2
	elseif op == 0x41 then -- DEC HL
		self:setHL(self:getHL() - 1)
		return 2
	elseif op == 0x42 then -- INC A
		local result = self.A + 1
		if result > 0xFF then
			self:setFlag(FLAGS.C)
		end
		self.A = bit.band(result, 0xFF)
		if self.A == 0 then
			self:setFlag(FLAGS.Z)
		end
		return 1
	elseif op == 0x43 then -- DEC A
		local result = self.A - 1
		self:flag(FLAGS.C, result >= 0)
		self.A = bit.band(result, 0xFF)
		self:flag(FLAGS.Z, self.A == 0)
		return 1
	elseif op == 0x44 then -- INC B
		local result = self.B + 1
		self:flag(FLAGS.C, result > 0xFF)
		self.B = bit.band(result, 0xFF)
		self:flag(FLAGS.Z, self.B == 0)
		return 1
	elseif op == 0x45 then -- DEC B
		local result = self.B - 1
		self:flag(FLAGS.C, result >= 0)
		self.B = bit.band(result, 0xFF)
		self:flag(FLAGS.Z, self.B == 0)
		return 1
	elseif op == 0x50 then -- JMP imm16
		local lo = self:fetch()
		local hi = self:fetch()
		self.PC = bit.bor(bit.lshift(hi, 8), lo)
		return 3
	elseif op == 0x51 then -- JZ imm16
		local lo = self:fetch()
		local hi = self:fetch()
		if self:isFlagSet(FLAGS.Z) then
			self.PC = bit.bor(bit.lshift(hi, 8), lo)
		end
		return 3
	elseif op == 0x52 then -- JNZ imm16
		local lo = self:fetch()
		local hi = self:fetch()
		if not self:isFlagSet(FLAGS.Z) then
			self.PC = bit.bor(bit.lshift(hi, 8), lo)
		end
		return 3
	elseif op == 0x53 then -- BCC imm16
		local lo = self:fetch()
		local hi = self:fetch()
		if self:isFlagSet(FLAGS.C) then
			self.PC = bit.bor(bit.lshift(hi, 8), lo)
		end
		return 3
	elseif op == 0x54 then -- BNC imm16
		local lo = self:fetch()
		local hi = self:fetch()
		if not self:isFlagSet(FLAGS.C) then
			self.PC = bit.bor(bit.lshift(hi, 8), lo)
		end
		return 3
	elseif op == 0x60 then -- PHA
		self:push(self.A)
		return 3
	elseif op == 0x61 then -- PLA
		self.A = self:pop()
		if self.A == 0 then
			self:setFlag(FLAGS.Z)
		end
		return 3
	elseif op == 0x62 then -- PHB
		self:push(self.B)
		return 3
	elseif op == 0x63 then -- PLB
		self.B = self:pop()
		if self.B == 0 then
			self:setFlag(FLAGS.Z)
		end
		return 3
	elseif op == 0x64 then -- PHP
		local ptrType = self:fetch()
		local hi = 0
		local lo = 0

		if ptrType == 0x0 then
			hi = bit.band(bit.rshift(self.BP, 8), 0xFF)
			lo = bit.band(self.BP, 0xFF)
		elseif ptrType == 0x1 then
			hi = self.H
			lo = self.L
		elseif ptrType == 0x2 then
			hi = bit.band(bit.rshift(self.SP, 8), 0xFF)
			lo = bit.band(self.SP, 0xFF)
		end

		self:push(hi)
		self:push(lo)
		return 3
	elseif op == 0x65 then -- PLP
		local ptrType = self:fetch()
		local lo = self:pop()
		local hi = self:pop()

		if ptrType == 0x0 then
			self.BP = bit.bor(bit.lshift(hi, 8), lo)
		elseif ptrType == 0x1 then
			self.H = hi
			self.L = lo
		elseif ptrType == 0x2 then
			self.SP = bit.bor(bit.lshift(hi, 8), lo)
		end

		return 3
	elseif op == 0x66 then -- GETN
		local index = self:fetch()
		self.A = self.memory:read(self.BP + index)
		if self.A == 0 then
			self:setFlag(FLAGS.Z)
		end
	elseif op == 0x67 then -- GET
		local index = self:fetch()
		self.A = self.memory:read(self.BP - index)
		self:flag(FLAGS.Z, self.A == 0)
	elseif op == 0x68 then -- SETN
		local index = self:fetch()
		self.memory:write(self.BP + index, self.A)
	elseif op == 0x69 then -- SET
		local index = self:fetch()
		self.memory:write(self.BP - index, self.A)
	elseif op == 0x70 then -- CALL imm16
		local lo = self:fetch()
		local hi = self:fetch()
		local ret = bit.band(self.PC, 0xFFFF)
		self:push(bit.band(ret, 0xFF))
		self:push(bit.rshift(ret, 8))
		self.PC = bit.bor(bit.lshift(hi, 8), lo)
		return 4
	elseif op == 0x71 then -- RET
		local hi = self:pop()
		local lo = self:pop()
		self.PC = bit.bor(bit.lshift(hi, 8), lo)
		return 4
	elseif op == 0x72 then -- CMP A, #imm8
		local imm = self:fetch()
		local result = self.A - imm
		if result >= 0 then
			self:setFlag(FLAGS.C)
		else
			self:clearFlag(FLAGS.C)
		end
		if self.A == self.B then
			self:setFlag(FLAGS.Z)
		else
			self:clearFlag(FLAGS.Z)
		end
		if bit.band(result, 0x80) ~= 0 then
			self:setFlag(FLAGS.N)
		else
			self:clearFlag(FLAGS.N)
		end
		return 2
	elseif op == 0x73 then -- CMP A, B
		local result = self.A - self.B
		if result >= 0 then
			self:setFlag(FLAGS.C)
		else
			self:clearFlag(FLAGS.C)
		end
		if self.A == self.B then
			self:setFlag(FLAGS.Z)
		else
			self:clearFlag(FLAGS.Z)
		end
		if bit.band(result, 0x80) ~= 0 then
			self:setFlag(FLAGS.N)
		else
			self:clearFlag(FLAGS.N)
		end
		return 2
	elseif op == 0x74 then -- AND A, B
		local result = bit.band(self.A, self.B)
		self.A = result
		self:flag(FLAGS.Z, result == 0)
		self:flag(FLAGS.N, bit.band(result, 0x80) ~= 0)
		self:flag(FLAGS.C, false)
		self:flag(FLAGS.V, false)
		return 1
	elseif op == 0x75 then -- OR A, B
		local result = bit.bor(self.A, self.B)
		self.A = result
		self:flag(FLAGS.Z, result == 0)
		self:flag(FLAGS.N, bit.band(result, 0x80) ~= 0)
		self:flag(FLAGS.C, false)
		self:flag(FLAGS.V, false)
		return 1
	elseif op == 0x76 then -- XOR A, B
		local result = bit.bxor(self.A, self.B)
		self.A = result
		self:flag(FLAGS.Z, result == 0)
		self:flag(FLAGS.N, bit.band(result, 0x80) ~= 0)
		self:flag(FLAGS.C, false)
		self:flag(FLAGS.V, false)
		return 1
	elseif op == 0x77 then -- NOT A
		self.A = bit.bnot(self.A)
		self:flag(FLAGS.Z, self.A == 0)
		self:flag(FLAGS.N, bit.band(self.A, 0x80) ~= 0)
		self:flag(FLAGS.C, false)
		self:flag(FLAGS.V, false)
		return 1
	elseif op == 0x78 then -- SHL A
		local result = bit.lshift(self.A, 1)
		self:flag(FLAGS.C, bit.band(result, 0x100) ~= 0)
		self.A = bit.band(result, 0xFF)
		self:flag(FLAGS.Z, self.A == 0)
		self:flag(FLAGS.N, bit.band(self.A, 0x80) ~= 0)
		self:flag(FLAGS.V, false)
		return 1
	elseif op == 0x79 then -- SHR A
		local result = bit.rshift(self.A, 1)
		self:flag(FLAGS.C, bit.band(self.A, 0x01) ~= 0)
		self.A = result
		self:flag(FLAGS.Z, self.A == 0)
		self:flag(FLAGS.N, false)
		self:flag(FLAGS.V, false)
		return 1
	elseif op == 0x80 then -- EI
		self:flag(FLAGS.I, true)
		return 1
	elseif op == 0x81 then -- DI
		self:flag(FLAGS.I, false)
		return 1
	elseif op == 0x82 then -- JMP (HL)
		self.PC = self:getHL()
	elseif op == 0x83 then -- CALL (HL)
		local addr = self:getHL()
		self:push(bit.band(self.PC, 0xFF))
		self:push(bit.rshift(self.PC, 8))
		self.PC = addr
		return 4
	elseif op == 0x84 then -- RETI
		local hi = self:pop()
		local lo = self:pop()
		self.PC = bit.bor(bit.lshift(hi, 8), lo)
		self:flag(FLAGS.I, true)
		return 4
	elseif op == 0x90 then -- BRK
		-- push PC & SR, clear B flag, set I, jump to IRQ vector
		local pc_hi = bit.rshift(self.PC, 8)
		local pc_lo = bit.band(self.PC, 0xFF)
		self:push(pc_hi)
		self:push(pc_lo)
		self:push(self.SR)
		self:flag(FLAGS.B, true)
		self:flag(FLAGS.I, true)
		local lo = self.memory:read(0xFFFE)
		local hi = self.memory:read(0xFFFF)
		self.PC = bit.bor(bit.lshift(hi, 8), lo)
		return 7
	elseif op == 0xA0 then -- GPTN
		local index = self.BP + self:fetch()
		self.L = self.memory:read(index)
		self.H = self.memory:read(index + 1)
	elseif op == 0xA1 then -- GPT
		local index = self.BP - self:fetch()
		self.L = self.memory:read(index)
		self.H = self.memory:read(index + 1)
	elseif op == 0xA2 then -- SPTN
		local index = self.BP + self:fetch()
		self.memory:write(index, self.L)
		self.memory:write(index + 1, self.H)
	elseif op == 0xA3 then -- SPT
		local index = self.BP - self:fetch()
		self.memory:write(index, self.L)
		self.memory:write(index + 1, self.H)
	elseif op == 0xFF then -- HALT
		self.halted = true
		return 0
	else -- NOP / undefined
		return 1
	end
end

return CPU
