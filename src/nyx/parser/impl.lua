local FunctionParser = require("src.nyx.parser.function")

local ImplParser = {}

function ImplParser:parse()
	self:expect("IMPL")
	local name = self:expect("IDENTIFIER")
	local body = {}
	while self.current and self.current.type ~= "END" do
		table.insert(body, self:node("ImplMethod", FunctionParser.parse(self, true)))
	end
	self:expect("END")
	return self:node("ImplDeclaration", {
		name = name.value,
		body = body,
		line = name.line,
	})
end

return ImplParser
