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
				name = varName,
				type = varType,
			})
		)
	end
	self:expect("END")
	return self:node("StructDeclaration", {
		name = name,
		body = body,
	})
end

return StructParser
