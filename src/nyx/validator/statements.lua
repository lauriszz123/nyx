local visitors = {}

local function register(name, func)
	visitors[name] = func
end

register("Program", require("src.nyx.validator.program"))

register("VariableDeclaration", require("src.nyx.validator.vardecl"))
register("FunctionDeclaration", require("src.nyx.validator.function"))
register("StructDeclaration", require("src.nyx.validator.struct"))
register("ImplDeclaration", require("src.nyx.validator.impl"))

register("IfStatement", require("src.nyx.validator.ifstmt"))
register("WhileStatement", require("src.nyx.validator.whilestmt"))
register("ForStatement", require("src.nyx.validator.forstmt"))
register("AssignmentStatement", require("src.nyx.validator.assignment"))
register("ReturnStatement", require("src.nyx.validator.return"))
register("ExpressionStatement", require("src.nyx.validator.exprstat"))

return visitors
