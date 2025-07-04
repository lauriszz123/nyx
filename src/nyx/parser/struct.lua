---@class StructParser: BaseParser
local StructParser = {}

function StructParser:parse()
	self:expect("STRUCT")
	local name = self:expect("IDENTIFIER")
	local body = {}
	self:expect("CURLY", "{")
	while self.current and (self.current.type ~= "CURLY" and self.current.value ~= "}") do
		local varName = self:expect("IDENTIFIER")
		self:expect("COLON")
		local varType = self:expect("IDENTIFIER")
		local ofType
		if self.current.type == "OF" then
			self:advance()
			ofType = self:expect("IDENTIFIER").value
		end
		if self.current.value ~= "}" then
			self:expect("COMMA")
		end
		table.insert(
			body,
			self:node("StructField", {
				name = varName.value,
				type = varType.value,
				of = ofType,
				line = varName.line,
			})
		)
	end
	self:expect("CURLY", "}")
	return self:node("StructDeclaration", {
		name = name.value,
		body = body,
		line = name.line,
	})
end

return StructParser
