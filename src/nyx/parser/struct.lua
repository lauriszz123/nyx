---@class StructParser: BaseParser
local StructParser = {}

function StructParser:parse()
	self:expect("STRUCT")
	local name = self:expect("IDENTIFIER")
	local body = {}
	while self.current and self.current.type ~= "END" do
		local varName = self:expect("IDENTIFIER")
		self:expect("COLON")
		local varType = self:expect("IDENTIFIER")
		self:expect("SEMICOLON")
		table.insert(
			body,
			self:node("StructField", {
				name = varName.value,
				type = varType.value,
				line = varName.line,
			})
		)
	end
	self:expect("END")
	return self:node("StructDeclaration", {
		name = name.value,
		body = body,
		line = name.line,
	})
end

return StructParser
