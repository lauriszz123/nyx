# CPU Instruction Set Reference

This document provides a comprehensive reference for the instruction set of the custom CPU, including opcodes, assembly mnemonics, operands, description, flags affected, and clock cycles.

## Register Set
- **A**: 8-bit Accumulator
- **B**: 8-bit General Purpose Register
- **HL**: 16-bit Address Register (H = high byte, L = low byte)
- **SP**: 16-bit Stack Pointer
- **PC**: 16-bit Program Counter
- **SR**: Status Register (Flags)

## Status Flags
- **C**: Carry Flag (0x01)
- **Z**: Zero Flag (0x02)
- **I**: Interrupt Flag (0x04)
- **D**: Decimal Flag (0x08)
- **B**: Break Flag (0x10)
- **V**: Overflow Flag (0x20)
- **N**: Negative Flag (0x40)

## Instruction Set

imm16, imm8 = $hex_number or #dec_number

| Opcode | Mnemonic | Operands | Description | Flags Affected | Cycles |
|--------|----------|----------|-------------|----------------|--------|
| 0x10   | LDA      | #imm8 | Load immediate 8-bit value into A | Z | 2 |
| 0x11   | LDB      | #imm8 | Load immediate 8-bit value into B | Z | 2 |
| 0x12   | LDHL     | (#imm16) | Load immediate 16-bit value into HL | - | 3 |
| 0x20   | LDA      | (HL) | Load value from memory at address HL into A | Z | 3 |
| 0x21   | STA      | (HL) | Store value from A into memory at address HL | - | 3 |
| 0x22   | LDA      | (#imm16) | Load value from memory at immediate address into A | Z | 4 |
| 0x23   | STA      | (#imm16) | Store value from A into memory at immediate address | - | 4 |
| 0x30   | ADD      |      | Add B to A | C, Z | 1 |
| 0x31   | SUB      |      | Subtract B from A | C, Z | 1 |
| 0x32   | MUL      |      | Multiply A by B | C, Z | 1 |
| 0x33   | DIV      |      | Divide A by B | C, Z | 1 |
| 0x40   | INHL     |      | Increment HL | - | 2 |
| 0x41   | DEHL     |      | Decrement HL | - | 2 |
| 0x42   | INA      |      | Increment A | C, Z | 1 |
| 0x43   | DEA      |      | Decrement A | C, Z | 1 |
| 0x44   | INB      |      | Increment B | C, Z | 1 |
| 0x45   | DEB      |      | Decrement B | C, Z | 1 |
| 0x50   | JMP      | (imm16) | Jump to immediate address | - | 3 |
| 0x51   | JZ       | (#imm16) | Jump to immediate address if Z flag is set | - | 3 |
| 0x52   | JNZ      | (#imm16) | Jump to immediate address if Z flag is clear | - | 3 |
| 0x60   | PHA      |      | Push A onto stack | - | 3 |
| 0x61   | PLA      |      | Pop value from stack into A | Z | 3 |
| 0x62   | PHB      |      | Push B onto stack | - | 3 |
| 0x63   | PLB      |      | Pop value from stack into B | Z | 3 |
| 0x70   | CALL     | (#imm16) | Call subroutine at immediate address | - | 4 |
| 0x71   | RET      |      | Return from subroutine | - | 4 |
| 0x72   | CMP      | #imm8 | Compare A with immediate value | C, Z, N, V | 2 |
| 0x73   | CMP      |      | Compare A with B | C, Z, N, V | 1 |
| 0x74   | AND      |      | Logical AND B with A | Z, N, C, V | 1 |
| 0x75   | OR       |      | Logical OR B with A | Z, N, C, V | 1 |
| 0x76   | XOR      |      | Logical XOR B with A | Z, N, C, V | 1 |
| 0x77   | NOT      |      | Logical NOT of A | Z, N, C, V | 1 |
| 0x78   | SHL      |      | Shift A left | C, Z, N, V | 1 |
| 0x79   | SHR      |      | Shift A right | C, Z, N, V | 1 |
| 0x80   | EI       |      | Enable interrupts | I | 1 |
| 0x81   | DI       |      | Disable interrupts | I | 1 |
| 0x82   | JMP      | (HL) | Jump to address stored in HL | - | 1 |
| 0x83   | CALL     | (HL) | Call subroutine at address stored in HL | - | 4 |
| 0x84   | RETI     |      | Return from interrupt | I | 4 |
| 0x90   | BRK      |      | Software interrupt | B, I | 7 |
| 0xFF   | HALT     |      | Halt the CPU | - | 1 |
| Other  | NOP      |      | No operation | - | 1 |

## Assembly Syntax Examples

```assembly
; Load immediate values
LD A, 42       ; Load decimal value 42 into A
LD B, 0xFF     ; Load hex value FF into B
LD HL, 0x4000  ; Load hex value 4000 into HL

; Memory operations
LD A, (HL)     ; Load value at address in HL into A
LD (HL), A     ; Store A to address in HL
LDA (0x2000)   ; Load value at address 0x2000 into A
STA (0x2000)   ; Store A to address 0x2000

; Arithmetic operations
ADD A, B       ; A = A + B
SUB A, B       ; A = A - B
MUL A, B       ; A = A * B
DIV A, B       ; A = A / B

; Increment and decrement
INC HL         ; HL = HL + 1
DEC HL         ; HL = HL - 1
INC A          ; A = A + 1
DEC A          ; A = A - 1
INC B          ; B = B + 1
DEC B          ; B = B - 1

; Jump instructions
JMP 0x4000     ; Jump to address 0x4000
JZ 0x4000      ; Jump to 0x4000 if zero flag is set
JNZ 0x4000     ; Jump to 0x4000 if zero flag is clear
JMP (HL)       ; Jump to address stored in HL

; Stack operations
PUSH A         ; Push A onto stack
POP A          ; Pop value from stack into A
PUSH B         ; Push B onto stack
POP B          ; Pop value from stack into B

; Subroutine operations
CALL 0x5000    ; Call subroutine at address 0x5000
RET            ; Return from subroutine
CALL (HL)      ; Call subroutine at address stored in HL
RETI           ; Return from interrupt

; Compare operations
CMP A, 42      ; Compare A with immediate value 42
CMP A, B       ; Compare A with B

; Logical operations
AND A, B       ; A = A AND B
OR A, B        ; A = A OR B
XOR A, B       ; A = A XOR B
NOT A          ; A = NOT A
SHL A          ; Shift A left one bit
SHR A          ; Shift A right one bit

; Interrupt control
EI             ; Enable interrupts
DI             ; Disable interrupts
BRK            ; Software interrupt
HALT           ; Halt CPU execution
```

## Memory Map

- **0x0000-0x3FFF**: ROM (16KB)
- **0x4000-0x7FFF**: RAM (16KB)
- **0x8000-0xFFFD**: I/O and Expansion
- **0xFFFE-0xFFFF**: Interrupt Vector

## Addressing Modes

1. **Immediate**: Value is included in the instruction
   - Example: `LD A, 42`

2. **Register**: Operation involves registers only
   - Example: `ADD A, B`

3. **Register Indirect**: Address is contained in a register
   - Example: `LD A, (HL)`

4. **Absolute**: Full 16-bit address is specified in the instruction
   - Example: `LDA (0x2000)`

## Programming Notes

- The stack grows downward (SP decrements on PUSH)
- The default reset vector is 0x4000
- The interrupt vector is located at 0xFFFE-0xFFFF
- Interrupts are enabled by default after reset