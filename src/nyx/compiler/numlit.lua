return function(self, node)
	self:emit("LDA", "#" .. node.value)
end
