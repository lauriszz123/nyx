local Visitor = {}

Visitor.Program = require("src.nyx.compiler.program")
Visitor.VariableDeclaration = require("src.nyx.compiler.vardecl")

return Visitor
