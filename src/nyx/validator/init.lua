local class = require("middleclass")
local AST = require("src.nyx.ast")
local Scope = require("src.nyx.scope")

---@class Validator
local Validator = class("Validator")

-- Initialize with a fresh scope
function Validator:initialize()
	---@type Scope
	self.scope = Scope()
	self.errors = {}
	self.currentFunction = nil
	self.visitor = require("src.nyx.validator.statements")
	self.expression = require("src.nyx.validator.expression")
end

function Validator:addError(message, node)
	local error = {
		message = message,
		line = node.line or -1,
	}
	table.insert(self.errors, error)
end

function Validator:validate(ast)
	AST.visit(self, ast)
end

function Validator:printResults()
	if #self.errors > 0 then
		print("=== VALIDATOR ERRORS ===")
		for _, err in ipairs(self.errors) do
			print(string.format("Error at line %d: %s", err.line, err.message))
		end
	end

	if #self.errors == 0 then
		print("No issues found!")
	end
end

return Validator
