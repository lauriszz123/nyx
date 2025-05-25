local class = require("middleclass")

local AST = class("AST")
local ASTNode = class("ASTNode")

AST.Node = ASTNode

function ASTNode:initialize(kind, props)
	for k, v in pairs(props or {}) do
		self[k] = v
	end
	self.kind = kind
end

-- Simple Visitor Dispatcher
function AST.visit(node, visitor, self)
	if node == nil then print('returned') return end
	local handler = visitor[node.kind]
	if handler then
		return handler(node, self)
	else
		return "No visitor handler for node kind: " .. node.kind
	end
end

return AST
