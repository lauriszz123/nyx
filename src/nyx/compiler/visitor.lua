local Visitor = {}

Visitor.Program = require("src.nyx.compiler.program")
Visitor.VariableDeclaration = require("src.nyx.compiler.vardecl")
Visitor.FunctionDeclaration = require("src.nyx.compiler.funcdecl")
Visitor.StructDeclaration = require("src.nyx.compiler.structdecl")
Visitor.ForStatement = require("src.nyx.compiler.forstmt")
Visitor.WhileStatement = require("src.nyx.compiler.whilestmt")
Visitor.IfStatement = require("src.nyx.compiler.ifstmt")
Visitor.AssignmentStatement = require("src.nyx.compiler.assgnstmt")
Visitor.ReturnStatement = require("src.nyx.compiler.retstmt")
Visitor.ExpressionStatement = require("src.nyx.compiler.exprstat")
Visitor.CallExpression = require("src.nyx.compiler.callexpr")
Visitor.BinaryExpression = require("src.nyx.compiler.binexpr")
Visitor.FieldAccess = require("src.nyx.compiler.fieldaccess")
Visitor.Identifier = require("src.nyx.compiler.ident")
Visitor.NumberLiteral = require("src.nyx.compiler.numlit")
Visitor.StringLiteral = require("src.nyx.compiler.strlit")

return Visitor
