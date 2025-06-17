local Visitor = {}

Visitor.Program = require("src.nyx.compiler.program")
Visitor.VariableDeclaration = require("src.nyx.compiler.vardecl")
Visitor.NumberLiteral = require("src.nyx.compiler.numlit")

return Visitor
