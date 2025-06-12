local f = string.format
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
}

return messages
