# Fantasy Virtual Machine (FVM) Design

This document outlines the design of a **fantasy virtual machine (FVM)** with a minified 6502‐inspired bytecode architecture, interrupt support, and dynamically connectable hardware devices (keyboard, mouse, screen, timer, etc.). The VM is designed for implementation in **Lua** using **LÖVE (Love2D)**.

---

## 1. Overview

- **Architecture**: 8‐bit core with 16‐bit addressing via `HL` register pair.
- **Memory**: 64 KB address space with RAM, stack, memory‐mapped I/O, and ROM.
- **Devices**: Screen, keyboard, mouse, timer, plus support for dynamic connect/disconnect.
- **Interrupts**: Software (`BRK`) and hardware interrupts with configurable vectors.
- **Bytecode**: Fixed‐width (2–3 bytes) opcodes, trivial to assemble/compile.
- **Implementation**: Written in Lua; LÖVE handles rendering and input.

---

## 2. Registers & Flags

| Register | Size  | Description                         |
|:--------:|:-----:|:------------------------------------|
| **A**    | 8 bit | Accumulator                         |
| **B**    | 8 bit | General register                    |
| **H**    | 8 bit | High byte of address pair           |
| **L**    | 8 bit | Low byte of address pair            |
| **HL**   | 16 bit| Combined address register           |
| **SP**   | 16 bit| Stack Pointer (initial at 0x1FFF)   |
| **PC**   | 16 bit| Program Counter                     |
| **SR**   | 8 bit | Status flags: `Z C I - D B V N`     |

- **Stack**: Grows downward from `0x1FFF` into `0x1F00–0x1FFF` region.

---

## 3. Memory Map

| Address Range   | Size      | Usage                            |
|---------------: |:---------:|:---------------------------------|
| `0x0000–0x1EFF` | 7.75 KB   | RAM                               |
| `0x1F00–0x1FFF` | 256 B     | **Stack**                         |
| `0x2000–0x2FFF` | 4 KB      | **Memory‐Mapped I/O**             |
| `0x3000–0x3FFF` | 4 KB      | Reserved / Expansion              |
| `0x4000–0xFFFD` | 48 KB     | ROM / Program Space               |
| `0xFFFE–0xFFFF` | 4 B       | **Interrupt Vectors**             |

---

## 4. Device Architecture

All devices implement a simple interface:

- **`connect()`**: Initialize device and map registers.
- **`disconnect()`**: Clean up and unmap registers.
- **`read(addr)`** / **`write(addr, value)`**: Handle I/O accesses.
- **`update(dt)`**: Optional periodic update (e.g., timer).  

### 4.1 Device Map (0x2000 Base)

| Addr        | Device       | Description                        |
|:-----------:|:-------------|:-----------------------------------|
| `0x2000`    | KBD_BUF      | Last keycode                       |
| `0x2001`    | KBD_STATE    | Modifier & key‐down flags          |
| `0x2002–0x2003` | MOUSE_X/Y| Mouse coordinates                  |
| `0x2004`    | MOUSE_BTN    | Button bitfield                    |
| `0x2005`    | TIMER_CNT    | 8‐bit counter                      |
| `0x2006`    | TIMER_CTRL   | [EN][IRQ][–][–][–][–][–][–]        |
| `0x2100–0x2FFF` | **SCREEN VRAM** | Framebuffer data (4 KB)     |

- **Screen**: Treated as a device with its own VRAM; high‐speed block transfer supported.

---

## 5. Interrupts

| Vector      | Address      | Type                            |
|:-----------:|:------------:|:--------------------------------|
| NMI         | `0xFFFA–0xFFFB` | Non‐maskable interrupt       |
| RESET       | `0xFFFC–0xFFFD` | Power‐on/reset vector        |
| IRQ / BRK   | `0xFFFE–0xFFFF` | Maskable interrupt / BRK     |

- **I Flag** (`SR` bit 2) controls global IRQ enable/disable.
- On interrupt: push `PC`, `SR`; clear `B`; set `I`; set `PC` to vector.

---

## 6. Bytecode Specification

- **Instruction width**: 2 bytes for most; 3 bytes for 16‐bit immediates.
- **Format**: `[opcode] [operand] [optional extra byte]` ensures fixed dispatch.

| Opcode | Mnemonic        | Bytes         | Cycles | Description                     |
|:------:|:----------------|:-------------:|:------:|:--------------------------------|
| `0x10` | `LD A, #imm8`   | 2             | 2      | Load 8‐bit immediate into A     |
| `0x11` | `LD B, #imm8`   | 2             | 2      | Load into B                     |
| `0x12` | `LD HL,#imm16`  | 3             | 3      | Load 16‐bit into HL             |
| `0x20` | `LD A,(HL)`     | 2             | 3      | A ← M[HL]                       |
| `0x21` | `LD (HL),A`     | 2             | 3      | M[HL] ← A                       |
| `0x30` | `ADD A,B`       | 2             | 1      | A ← A + B                       |
| `0x31` | `SUB A,B`       | 2             | 1      | A ← A – B                       |
| `0x40` | `INC HL`        | 2             | 2      | HL ← HL + 1                     |
| `0x41` | `DEC HL`        | 2             | 2      | HL ← HL – 1                     |
| `0x50` | `JMP imm16`     | 3             | 3      | PC ← immediate                  |
| `0x51` | `JZ imm16`      | 3             | 3      | If Z=1, PC ← immediate          |
| `0x60` | `PUSH A`        | 2             | 3      | Push A onto stack               |
| `0x61` | `POP A`         | 2             | 3      | Pop from stack into A           |
| `0x70` | `CALL imm16`    | 3             | 4      | Push return; PC ← immediate     |
| `0x71` | `RET`           | 2             | 4      | Pop PC                          |
| `0x80` | `EI`            | 2             | 1      | Enable interrupts               |
| `0x81` | `DI`            | 2             | 1      | Disable interrupts              |
| `0x90` | `BRK`           | 2             | 7      | Software interrupt              |
| `0xFF` | `NOP`           | 2             | 1      | No operation                    |

---

## 7. Device Manager & Hot‐Plugging

Implement a **Device Manager** in `vm.lua`:

```lua
DeviceManager = {
  devices = {},
  map = {},
}

function DeviceManager:connect(name, dev)
  self.devices[name] = dev
  dev:connect()
  for addr in dev:addresses() do
    self.map[addr] = dev
  end
end

function DeviceManager:disconnect(name)
  local dev = self.devices[name]
  dev:disconnect()
  for addr in dev:addresses() do
    self.map[addr] = nil
  end
  self.devices[name] = nil
end

function DeviceManager:read(addr)
  local dev = self.map[addr]
  if dev then return dev:read(addr) end
  return RAM[addr]
end

function DeviceManager:write(addr,v)
  local dev = self.map[addr]
  if dev then return dev:write(addr,v) end
  RAM[addr] = v
end
```

- Supports **connect/disconnect** at runtime.
- Devices can be added or removed (e.g., hot‐swap screen, keyboard).

---

## 8. Screen Device & VRAM

Treat screen as a **device** with its own VRAM region:

```lua
Screen = {
  base = 0x2100,
  size = 0xF00,  -- 3840 bytes (e.g. 120x32) or full 4K as needed
}

function Screen:connect()
  self.vram = love.image.newImageData(width, height)
end

function Screen:read(addr)
  return self.vram:getPixel(addr - self.base, 0)  -- simplified
end

function Screen:write(addr, value)
  local x, y = self:decode(addr)
  self.vram:setPixel(x,y, value, value, value, 1)
end

function Screen:update(dt)
  -- redraw canvas if needed
end
```

- **High‐speed VRAM**: bulk transfers via `memcpy`‐like ops in Lua when updating canvas.

---

## 9. Lua & Love2D Integration

- **main.lua**: Boot VM, load ROM, connect default devices.
- **cpu.lua**: Fetch/decode/execute, register file, flags.
- **memory.lua**: Delegates to DeviceManager for I/O.
- **devices/**: Modules for each device (`keyboard.lua`, `mouse.lua`, `timer.lua`, `screen.lua`).
- **vm.lua**: Ties CPU, memory, devices, interrupt handling.

**Workflow**:
1. `love.load()`: init VM, connect devices.
2. `love.update(dt)`: run CPU cycles, call `Device:update(dt)`, handle interrupts.
3. `love.draw()`: draw screen device’s canvas.
4. `love.keypressed/released`, `love.mouse*`: write to device maps.

---

## 10. Example Bytecode

```asm
; Fill screen with pattern then wait for key
LD HL,#0x2100        ; Load VRAM base
LD A,#0xAA           ; Pattern
LOOP:
  LD (HL),A          ; Store
  INC HL             ; Next pixel
  CP HL,#0x3000      ; End of VRAM?
  JZ DONE
  JMP LOOP
DONE:
  BRK                ; Wait for interrupt
```

---

This design balances **simplicity** (fixed‐width instructions, unified device framework) with **power** (dynamic peripherals, high‐speed screen, full interrupt support). It provides a clear roadmap for your Lua + LÖVE implementation.  