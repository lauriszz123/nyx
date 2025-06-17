return function(self, node, outType)
	if outType == "u8" or outType == "s8" then
		self:emit("LDA", "#" .. node.value)
	elseif outType == "ptr" then
		self:emit("LDHL", "#" .. node.value)
	else
		print("Unsupported outType on numlit:", outType)
		error()
	end
end
