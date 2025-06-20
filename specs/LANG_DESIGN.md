# Nyx Language Design

Nyx is a statically-typed, language inspired by Lua, intended for easy compilation to a CHIP-8, 6502 style VM architecture.

---

## 1. Philosophy
- Minimalist core syntax, expandable via libraries.
- All types are implemented as structs.
- No dynamic types at the core level.
- Self-hostable: even `Array`, `Table`, `Heap`, etc. are written in Nyx.
- Designed for low-level VMs: operations are easy to compile to CHIP-8-like opcodes (A, B, H, L registers).

---

## 2. Core Syntax

### 2.1 Structs
```lua
struct Name
  field: Type
  local privateField: Type
end
```
- `struct` defines a new struct.
- Fields assigned directly are public.
- Fields defined via `local` are private.

### 2.2 Variables
```lua
local x: Type = value    -- Private or local
x: Type = value          -- Public
```

### 2.3 Functions
Functions are pretty similair to Lua, but with statically-typed sugar.
```lua
function name(params: Types, ...): ReturnType
  ...
end
```

### 2.4 Control Flow
```lua
if condition then
  ...
elseif condition then
  ...
else
  ...
end

while condition do
  ...
end

for i = start, stop, step do
  ...
end

switch value
  case pattern: ... break
  default: ...
end
```

### 2.5 Expressions
- Arithmetic: `+`, `-`, `*`, `/`
- Comparisons: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Logical: `and`, `or`, `not`
- Function calls: `foo(x, y)`
- Lambda functions: `(x: Type) => x + 1`

---

## 3. Memory Model
- Memory is accessed through VM primitives:
  - `peek(addr: Pointer): u8`
  - `poke(addr: Pointer, value: u8): void`
- Userland `Heap` class manages allocations:
```lua
struct Heap
  static freePtr: ptr = HEAP_START

  function alloc(size: u8): Pointer
    if freePtr + size > HEAP_END then
      error("Out of memory")
    end
    local ptr = freePtr
    freePtr = freePtr + size
    return ptr
  end
end
```

---

## 4. Virtual Machine Target
- Registers: `A`, `B`, `H`, `L` (High, Low)
- 16-bit address space via H:L pairing.
- Bytecode operations:
  - `LOAD_CONST`, `LOAD_VAR`, `STORE_VAR`
  - Arithmetic: `ADD`, `SUB`, `MUL`, `DIV`
  - Memory: `PEEK`, `POKE`
  - Control flow: `JMP`, `JEQ`, `CALL`, `RET`

---

## 5. Type System
- All types are defined by structs.
- No separate `type` keyword; everything is a `struct`.
- Functions can be typed for parameters and return types.
- Generics supported manually: e.g., `Array<T>`
- Interfaces supported for structural typing.

---

## 6. Example
```lua
class Array<T> do
  data: Pointer
  length: UInt16

  static function ofSize(len: UInt16): Array<T>
    local base = Heap.alloc(len * sizeof(T))
    return Array { data = base, length = len }
  end

  function get(self, index: UInt16): T
    return peek(self.data + index * sizeof(T))
  end
end
```

---

## 7. Compiler Pipeline
- **Lexer**: Tokenizes identifiers, keywords, operators, literals.
- **Parser**: Builds an AST with `kind` tagged nodes.
- **Visitor/Typechecker**: Resolves types, checks assignments, method calls.
- **Codegen**: Outputs CHIP-8-style bytecode.

---

## Future Extensions
- GC (Garbage Collection)
- Coroutines (simple yield/resume)
- Exception handling (`try/catch/finally`)
- Module system (`import/export`)
- More complex pattern matching inside `switch`

---

This document outlines the foundation for Nyx!
