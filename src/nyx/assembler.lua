local class = require("middleclass")
local inspect = require("inspect")

local Lexer = require("src.nyx.lexer")

---@class Assembler
local Assembler = class("Assembler")

-- Constructor
function Assembler:initialize(sourceCode, programOffset)
	-- Setup instruction set
	self:setupInstructionSet()

	-- Setup addressing modes
	self:setupAddressingModes()

	-- Initialize the assembler with source code
	self:reset(sourceCode)

	self.programOffset = programOffset or 0x0000 -- Default program offset
end

-- Setup instruction set in a separate method for better organization
function Assembler:setupInstructionSet()
	-- Create instruction table with opcode, addressing modes and size
	self.instructions = {
		-- No Operation
		["NOP"] = {
			opcode = 0x00,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Load accumulator with immediate value
		["LDA"] = {
			opcode = 0x10,
			addrModes = { "immediate", "register_indirect", "direct" },
			sizes = { immediate = 2, register_indirect = 1, direct = 3 },
		},
		-- Load B register with immediate value
		["LDB"] = {
			opcode = 0x11,
			addrModes = { "immediate" },
			sizes = { immediate = 2 },
		},
		-- Load HL with immediate address
		["LDHL"] = {
			opcode = 0x12,
			addrModes = { "immediate", "direct" },
			sizes = { immediate = 3, direct = 3 },
		},
		-- Store accumulator to memory
		["STA"] = {
			opcode = 0x21,
			addrModes = { "register_indirect", "direct" },
			sizes = { register_indirect = 1, direct = 3 },
		},
		["STHL"] = {
			opcode = 0x25,
			addrModes = { "direct" },
			sizes = { direct = 3 },
		},
		["SBP"] = {
			opcode = 0x24,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Add B to A
		["ADD"] = {
			opcode = 0x30,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Subtract B from A
		["SUB"] = {
			opcode = 0x31,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Multiply A by B
		["MUL"] = {
			opcode = 0x32,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Divide A by B
		["DIV"] = {
			opcode = 0x33,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Increment HL
		["INHL"] = {
			opcode = 0x40,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Decrement HL
		["DEHL"] = {
			opcode = 0x41,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Increment A
		["INA"] = {
			opcode = 0x42,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Decrement A
		["DEA"] = {
			opcode = 0x43,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Increment B
		["INB"] = {
			opcode = 0x44,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Decrement B
		["DEB"] = {
			opcode = 0x45,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Jump to address
		["JMP"] = {
			opcode = 0x50,
			addrModes = { "direct", "register_indirect" },
			sizes = { direct = 3, register_indirect = 1 },
		},
		-- Jump if zero
		["JZ"] = {
			opcode = 0x51,
			addrModes = { "direct" },
			sizes = { direct = 3 },
		},
		-- Jump if not zero
		["JNZ"] = {
			opcode = 0x52,
			addrModes = { "direct" },
			sizes = { direct = 3 },
		},
		-- Push A to stack
		["PHA"] = {
			opcode = 0x60,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Pop from stack to A
		["PLA"] = {
			opcode = 0x61,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Push B to stack
		["PHB"] = {
			opcode = 0x62,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Pop from stack to B
		["PLB"] = {
			opcode = 0x63,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		["PHP"] = {
			opcode = 0x64,
			addrModes = { "immediate" },
			sizes = { immediate = 2 },
		},
		["PLP"] = {
			opcode = 0x65,
			addrModes = { "immediate" },
			sizes = { immediate = 2 },
		},
		["GETN"] = {
			opcode = 0x66,
			addrModes = { "immediate" },
			sizes = { immediate = 2 },
		},
		["GET"] = {
			opcode = 0x67,
			addrModes = { "immediate" },
			sizes = { immediate = 2 },
		},
		["SETN"] = {
			opcode = 0x68,
			addrModes = { "immediate" },
			sizes = { immediate = 2 },
		},
		["SET"] = {
			opcode = 0x69,
			addrModes = { "immediate" },
			sizes = { immediate = 2 },
		},
		-- Call subroutine
		["CALL"] = {
			opcode = 0x70,
			addrModes = { "direct", "register_indirect" },
			sizes = { direct = 3, register_indirect = 1 },
		},
		-- Return from subroutine
		["RET"] = {
			opcode = 0x71,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Compare A with immediate
		["CMP"] = {
			opcode = 0x72,
			addrModes = { "immediate", "implied" },
			sizes = { immediate = 2, implied = 1 },
		},
		-- Logical AND
		["AND"] = {
			opcode = 0x74,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Logical OR
		["OR"] = {
			opcode = 0x75,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Logical XOR
		["XOR"] = {
			opcode = 0x76,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Logical NOT
		["NOT"] = {
			opcode = 0x77,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Shift left
		["SHL"] = {
			opcode = 0x78,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Shift right
		["SHR"] = {
			opcode = 0x79,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Enable interrupts
		["EI"] = {
			opcode = 0x80,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Disable interrupts
		["DI"] = {
			opcode = 0x81,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Return from interrupt
		["RETI"] = {
			opcode = 0x84,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Software interrupt
		["BRK"] = {
			opcode = 0x90,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
		-- Halt execution
		["HLT"] = {
			opcode = 0xFF,
			addrModes = { "implied" },
			sizes = { implied = 1 },
		},
	}

	-- Setup opcode variants based on addressing modes
	for name, instr in pairs(self.instructions) do
		instr.variants = {}
		for _, mode in ipairs(instr.addrModes) do
			local opVariant = instr.opcode

			-- For LDA, we need to adjust the opcode based on addressing mode
			if name == "LDA" then
				if mode == "immediate" then
					opVariant = 0x10
				elseif mode == "register_indirect" then
					opVariant = 0x20
				elseif mode == "direct" then
					opVariant = 0x22
				end
			elseif name == "LDHL" then
				if mode == "immediate" then
					opVariant = 0x12
				elseif mode == "direct" then
					opVariant = 0x26
				end
				-- For STA, adjust opcode based on addressing mode
			elseif name == "STA" then
				if mode == "register_indirect" then
					opVariant = 0x21
				elseif mode == "direct" then
					opVariant = 0x23
				end
				-- For JMP, adjust opcode based on addressing mode
			elseif name == "JMP" then
				if mode == "direct" then
					opVariant = 0x50
				elseif mode == "register_indirect" then
					opVariant = 0x82
				end
				-- For CALL, adjust opcode based on addressing mode
			elseif name == "CALL" then
				if mode == "direct" then
					opVariant = 0x70
				elseif mode == "register_indirect" then
					opVariant = 0x83
				end
				-- For CMP, adjust opcode based on addressing mode
			elseif name == "CMP" then
				if mode == "immediate" then
					opVariant = 0x72
				elseif mode == "implied" then
					opVariant = 0x73
				end
			end

			instr.variants[mode] = opVariant
		end
	end

	-- Alias table for backward compatibility
	self.aliases = {}
end

-- Setup addressing modes patterns and handlers
function Assembler:setupAddressingModes()
	-- Define addressing modes and their patterns
	self.addressingModes = {
		-- Implied addressing (no operands)
		implied = {
			pattern = function()
				return true
			end, -- Always matches if no operands
			process = function()
				return { mode = "implied", bytes = {} }
			end,
		},

		-- Immediate addressing (#value)
		immediate = {
			pattern = function(token)
				return token and (token.type == "HASH" or token.type == "IDENTIFIER")
			end,
			process = function(self)
				if self.current.type == "HASH" then
					self:advance() -- Skip the hash
					local value = self:parseExpression()
					return {
						mode = "immediate",
						bytes = { value },
					}
				elseif self.current.type == "IDENTIFIER" then
					return {
						mode = "immediate",
						label = value,
					}
				else
					error("WTF")
				end
			end,
		},

		-- Direct addressing (address or label)
		direct = {
			pattern = function(token)
				return token and token.type == "PARENTHESIS" and token.value == "("
			end,
			process = function(self)
				self:advance() -- Skip the opening parenthesis
				local address = self:parseExpression()

				-- Expect closing parenthesis
				if not (self.current and self.current.type == "PARENTHESIS" and self.current.value == ")") then
					self:addError("Expected closing parenthesis in direct addressing mode")
				else
					self:advance() -- Skip the closing parenthesis
				end

				-- Just return the address/label as is - don't try to split bytes here
				return {
					mode = "direct",
					bytes = { address }, -- Store as single element, we'll handle byte splitting later
					label = type(address) == "string" and address or nil,
				}
			end,
		},

		-- Register Indirect addressing (HL)
		register_indirect = {
			pattern = function(token)
				return token
					and token.type == "PARENTHESIS"
					and token.value == "("
					and Assembler.peekMatches(token, 1, "IDENTIFIER", "HL")
					and Assembler.peekMatches(token, 2, "PARENTHESIS", ")")
			end,
			process = function(self)
				self:advance() -- Skip the opening parenthesis
				self:advance() -- Skip the HL
				self:advance() -- Skip the closing parenthesis
				return {
					mode = "register_indirect",
					bytes = {},
				}
			end,
		},
	}
end

-- Static helper to peek at tokens
function Assembler.peekMatches(currentToken, offset, type, value)
	local token = currentToken
	for i = 1, offset do
		if not token or not token.next then
			return false
		end
		token = token.next
	end
	return token and token.type == type and token.value == value
end

-- Reset the assembler with new source code
function Assembler:reset(sourceCode)
	-- Create lexer for the source code
	local lexer = Lexer(sourceCode, true)

	-- Initialize state
	self.currentAddress = 0
	self.labels = {}
	self.fixups = {} -- For forward references to labels
	self.bytecode = {}
	self.symbolTable = {}
	self.errors = {}

	-- Tokenize the source
	self.tokens = {}
	for token in lexer:iter() do
		table.insert(self.tokens, token)
	end

	-- Initialize position
	self.position = 1
	self.current = self.tokens[self.position]
end

-- Advance to the next token
function Assembler:advance()
	self.position = self.position + 1
	self.current = self.tokens[self.position]
	return self.current
end

-- Peek at the next token without advancing
function Assembler:peek(offset)
	offset = offset or 1
	return self.tokens[self.position + offset]
end

-- Expect a token of a specific type
function Assembler:expect(type)
	if self.current and self.current.type == type then
		local token = self.current
		self:advance()
		return token.value
	else
		self:addError(
			string.format(
				"Expected token '%s' but got '%s' at line %d col %d",
				type,
				self.current and self.current.type or "EOF",
				self.current and self.current.line or -1,
				self.current and self.current.col or -1
			)
		)
		return nil
	end
end

-- Add an error to the errors list
function Assembler:addError(message)
	table.insert(self.errors, {
		message = message,
		line = self.current and self.current.line,
		col = self.current and self.current.col,
	})
end

-- Fix for parseExpression to correctly handle labels
function Assembler:parseExpression()
	if not self.current then
		self:addError("Unexpected end of input while parsing expression")
		return 0
	end

	-- Handle numbers
	if self.current.type == "NUMBER" then
		return tonumber(self:expect("NUMBER"))
	elseif self.current.type == "HASH" then
		self:advance()
		return tonumber(self:expect("NUMBER"))
		-- Handle labels
	elseif self.current.type == "IDENTIFIER" then
		local label = self.current.value
		self:advance()
		return label
	elseif self.current.type == "CHAR" and self.current.value == "$" then
		self:advance() -- Skip the $ character

		if self.current and self.current.type == "NUMBER" then
			local value = tonumber(self.current.value, 16)
			self:advance()
			return value
		else
			self:addError("Expected number after '$' in hex literal")
			return 0
		end
	end

	self:addError("Expected number or identifier in expression")
	return 0
end

-- Parse an instruction operand
function Assembler:parseOperand(instruction)
	-- If no current token, return implied addressing if supported
	if not self.current then
		if table.contains(instruction.addrModes, "implied") then
			return { mode = "implied", bytes = {} }
		else
			self:addError(string.format("Expected operand for instruction '%s'", instruction.name))
			return { mode = "implied", bytes = {} }
		end
	end

	-- Check for register indirect addressing first (HL)
	if self.current and self.current.type == "PARENTHESIS" and self.current.value == "(" then
		local next = self:peek()
		if next and next.type == "IDENTIFIER" and next.value == "HL" then
			local nextNext = self:peek(2)
			if
				table.contains(instruction.addrModes, "register_indirect")
				and nextNext
				and nextNext.type == "PARENTHESIS"
				and nextNext.value == ")"
			then
				-- We have (HL) pattern
				self:advance() -- Skip (
				self:advance() -- Skip HL
				self:advance() -- Skip )
				return {
					mode = "register_indirect",
					bytes = {},
				}
			end
		end

		-- Check for direct addressing (label) or (address)
		if table.contains(instruction.addrModes, "direct") then
			-- For direct addressing, use a simple approach:
			self:advance() -- Skip opening parenthesis

			-- Parse expression inside parentheses (could be label or numeric address)
			local address = self:parseExpression()

			-- Check for closing parenthesis
			if not (self.current and self.current.type == "PARENTHESIS" and self.current.value == ")") then
				self:addError("Expected closing parenthesis")
			else
				self:advance() -- Skip closing parenthesis
			end

			return {
				mode = "direct",
				bytes = { address }, -- Just store the address/label as is
				label = type(address) == "string" and address or nil,
			}
		end
	end

	-- Check for immediate addressing (#value)
	if
		self.current
		and (self.current.type == "HASH" or self.current.type == "IDENTIFIER")
		and table.contains(instruction.addrModes, "immediate")
	then
		local value = self:parseExpression()
		return {
			mode = "immediate",
			bytes = { value },
		}
	end

	-- If no operands and implied addressing is supported
	if table.contains(instruction.addrModes, "implied") then
		return {
			mode = "implied",
			bytes = {},
		}
	end

	-- No matching addressing mode
	self:addError(string.format("Invalid addressing mode for instruction '%s'", instruction.name))
	return { mode = "implied", bytes = {} }
end

-- Process a label declaration
function Assembler:processLabel(name)
	self.labels[name] = self.programOffset + self.currentAddress
	print("Defined label: " .. name .. " = " .. self.currentAddress)
end

-- Emit a byte to the output bytecode
function Assembler:emitByte(byte)
	table.insert(self.bytecode, bit.band(byte, 0xFF))
	self.currentAddress = self.currentAddress + 1
end

-- Also fix the processInstruction function to properly handle labels in direct addressing
function Assembler:processInstruction(name)
	-- Get the instruction and handle aliases
	local instrName = self.aliases[name] or name
	local instruction = self.instructions[instrName]

	if not instruction then
		self:addError(string.format("Unknown instruction: %s", name))
		return
	end

	-- Parse the operand(s) based on addressing mode
	local operand = self:parseOperand(instruction)

	-- Get the opcode variant based on addressing mode
	local opcode = instruction.variants[operand.mode]

	-- Emit the opcode
	self:emitByte(opcode)

	-- Process operand bytes
	for _, byte in ipairs(operand.bytes) do
		if type(byte) == "string" then
			-- This is a label reference
			local labelPos = #self.bytecode + 1

			-- Create the fixups table for this label if it doesn't exist
			if not self.fixups[byte] then
				self.fixups[byte] = {}
			end

			-- Add to fixups regardless of whether the label exists yet
			table.insert(self.fixups[byte], { position = labelPos })

			-- Emit placeholders
			self:emitByte(0) -- Placeholder for low byte
			self:emitByte(0) -- Placeholder for high bytes
		else
			-- Regular numeric value
			if operand.mode == "direct" then
				-- For direct addressing with a numeric address, split into low/high bytes
				self:emitByte(byte)
				self:emitByte(bit.rshift(byte, 8))
			elseif instruction.sizes[operand.mode] == 3 then
				self:emitByte(byte)
				self:emitByte(bit.rshift(byte, 8))
			else
				-- For other addressing modes, just emit the byte
				self:emitByte(byte)
			end
		end
	end
end

-- Calculate instruction size based on addressing mode
function Assembler:calculateInstructionSize(name)
	local instrName = self.aliases[name] or name
	local instruction = self.instructions[instrName]

	if not instruction then
		print("Unknown instruction: " .. name)
		return 1 -- Default size for unknown instructions
	end

	-- Determine the addressing mode
	local mode = "implied"
	local next = self:peek()
	local next2 = self:peek(2)
	local next3 = self:peek(3)

	if next and next.type == "HASH" then
		mode = "immediate"
	elseif next and next.type == "PARENTHESIS" and next.value == "(" then
		if
			next2
			and next2.type == "IDENTIFIER"
			and next2.value == "HL"
			and next3
			and next3.type == "PARENTHESIS"
			and next3.value == ")"
		then
			mode = "register_indirect"
		else
			mode = "direct"
		end
	end

	return instruction.sizes[mode] or 1
end

-- First pass - Collect labels and calculate sizes
function Assembler:firstPass()
	self.currentAddress = 0
	while self.current do
		-- Handle labels (NAME:)
		if self.current.type == "IDENTIFIER" then
			local name = self.current.value
			self:advance()

			if name == "DB" then
				while self.current and self.current.type == "HASH" do
					local num = self:parseExpression()
					if num > 0xFF then
						self:addError("Data must be a byte!")
					end
					self.currentAddress = self.currentAddress + 1
					if self.current and self.current.type ~= "COMMA" then
						break
					end
				end
			else
				if self.current and self.current.type == "COLON" then
					self:advance() -- Skip the colon
					self:processLabel(name)
				elseif self.instructions[name] or self.aliases[name] then
					-- This is an instruction - get the instruction definition
					local instrName = self.aliases[name] or name
					local instruction = self.instructions[instrName]
					instruction.name = instrName

					-- Parse the operand using the same method as in secondPass
					local operand = self:parseOperand(instruction)

					-- Update the current address based on the actual size
					local size = instruction.sizes[operand.mode] or 1
					self.currentAddress = self.currentAddress + size
				else
					-- Unknown identifier
					self:addError(string.format("Unknown identifier: %s", name))
					self:advance()
				end
			end
		else
			self:advance()
		end
	end

	-- Reset position for second pass
	self.position = 1
	self.current = self.tokens[self.position]
	self.currentAddress = 0
	self.bytecode = {}
end

-- Second pass - Generate bytecode
function Assembler:secondPass()
	while self.current do
		if self.current.type == "IDENTIFIER" then
			local name = self.current.value
			self:advance()

			if self.current and self.current.type == "COLON" then
				self:advance() -- Skip the colon
				-- Label already processed in first pass
			elseif self.instructions[name] or self.aliases[name] then
				-- Process instruction
				self:processInstruction(name)
			elseif name == "DB" then
				self:emitByte(self:parseExpression())
			else
				-- Don't error on unknown identifiers in second pass
				-- Could be forward references that will be resolved later
				self:advance()
			end
		else
			self:advance()
		end
	end
end

-- Add a function to process AFTER the first pass to resolve fixups
function Assembler:resolveLabels()
	for label, fixups in pairs(self.fixups) do
		if self.labels[label] then
			-- Label exists, update all references
			local address = self.labels[label]
			for _, fixup in ipairs(fixups) do
				self.bytecode[fixup.position + 1] = bit.band(bit.rshift(address, 8), 0xFF) -- High byte
				self.bytecode[fixup.position] = bit.band(address, 0xFF) -- Low byte
			end
		else
			-- Report unresolved labels
			self:addError(string.format("Unresolved label: %s", label))
		end
	end
end

-- Assemble the source code into bytecode
function Assembler:assemble()
	-- First pass: collect labels and calculate instruction sizes
	self:firstPass()

	-- Second pass: generate bytecode
	self:secondPass()

	-- Resolve labels and fixups
	self:resolveLabels()

	-- Check for errors
	if #self.errors > 0 then
		print("Assembly failed with errors:")
		for _, err in ipairs(self.errors) do
			print(string.format("Line %d, Col %d: %s", err.line or 0, err.col or 0, err.message))
		end
		return nil
	end

	print("Assembly successful! Generated " .. #self.bytecode .. " bytes.")
	return self.bytecode
end

-- Add a custom instruction to the instruction set
function Assembler:addInstruction(name, opcode, addrModes, sizes)
	-- Default to implied addressing if not specified
	addrModes = addrModes or { "implied" }
	sizes = sizes or { implied = 1 }

	-- Create the instruction entry
	self.instructions[name] = {
		opcode = opcode,
		addrModes = addrModes,
		sizes = sizes,
		variants = {},
	}

	-- Setup variants based on addressing modes
	for _, mode in ipairs(addrModes) do
		-- By default, use the base opcode for all addressing modes
		-- You may need to override this in specific cases
		self.instructions[name].variants[mode] = opcode
	end

	return self
end

-- Add an alias for an instruction
function Assembler:addAlias(alias, originalName)
	self.aliases[alias] = originalName
	return self
end

-- Get the assembled bytecode
function Assembler:getBytecode()
	return self.bytecode
end

-- Get the labels (symbol table)
function Assembler:getLabels()
	return self.labels
end

-- Get assembly errors
function Assembler:getErrors()
	return self.errors
end

-- Format the bytecode as a hex dump
function Assembler:formatHexDump()
	local result = ""
	local address = 0

	for i = 1, #self.bytecode, 16 do
		result = result .. string.format("%04X: ", address)

		for j = i, math.min(i + 15, #self.bytecode) do
			result = result .. string.format("%02X ", self.bytecode[j])
		end

		result = result .. "\n"
		address = address + 16
	end

	return result
end

-- Return the Assembler class
return Assembler
