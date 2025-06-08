local visitors = {}

local function register(name, func)
	visitors[name] = func
end

register("Program", require("src.nyx.validator.program"))

register("VariableDeclaration", require("src.nyx.validator.vardecl"))

return visitors
