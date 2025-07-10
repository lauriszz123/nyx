local f = string.format

local function template(desc, name, correct)
	return f("%s\n\nCorrect definition of %s is:\n%s", desc, name, correct)
end

local messages = {
	IN_IMPL = function(exp, got)
		return f("Expected a function in 'impl' block, got unexpected type '%s'", got)
	end,
	ERR_TOK = function(exp, got)
		return f("Expected token '%s' but got '%s'!", exp, got)
	end,
	ERR_TOK_VAL = function(exp, got, expVal, gotVal)
		return f("Expected token '%s' with value '%s' but got '%s' with value '%s'!", exp, expVal, got, gotVal)
	end,
	ERR_CONST_DEFINITION_NAME = function()
		return template("Expected a name in const definition.", "const", "const name: type = value;")
	end,
	ERR_CONST_DEFINITION_TYPE = function()
		return template("Expected to define a type in const definition.", "const", "const name: type = value;")
	end,
	ERR_CONST_DEFINITION_ASSIGNMENT = function()
		return template(
			"Need to assign a value to a const, you cannot assign const after the definition.",
			"const",
			"const name: type = value;"
		)
	end,
	ERR_STATEMENT_SEMICOLON = function()
		return "Expected a semicolon at the end of the statement!"
	end,
}

return messages
