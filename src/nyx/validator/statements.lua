local visitors = {}

local function register(name, func)
	visitors[name] = func
end

register("Program", require("src.nyx.validator.program"))

register("VariableDeclaration", require("src.nyx.validator.vardecl"))
register("FunctionDeclaration", require("src.nyx.validator.function"))
register("ReturnStatement", require("src.nyx.validator.return"))

return visitors
