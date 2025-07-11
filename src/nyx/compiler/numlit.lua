return function(self, node, outType)
	if outType == "u8" or outType == "s8" then
		self:emit("const_u8", node.value)
	elseif outType == "ptr" or outType == "str" or outType == "u16" then
		self:emit("const_u16", node.value)
	else
		print("Unsupported outType on numlit:", outType)
		error()
	end
end
