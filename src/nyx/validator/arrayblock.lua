---@param self Validator
return function(self, node, against)
	for _, expr in ipairs(node.expressions) do
		local exprType = self.expression:getExpressionType(expr, against)
		if exprType ~= against then
			return exprType
		end
	end

	return against
end
