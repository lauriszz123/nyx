local Visitor = {}

Visitor.Program = require("src.nyx.compiler.program")
Visitor.VariableDeclaration = require("src.nyx.compiler.vardecl")
Visitor.AssignmentStatement = require("src.nyx.compiler.assgnstmt")
Visitor.ExpressionStatement = require("src.nyx.compiler.exprstat")
Visitor.CallExpression = require("src.nyx.compiler.callexpr")
Visitor.BinaryExpression = require("src.nyx.compiler.binexpr")
Visitor.NumberLiteral = require("src.nyx.compiler.numlit")
Visitor.Identifier = require("src.nyx.compiler.ident")

return Visitor
