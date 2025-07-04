local VM = require("src")
---@type SRC
local vm

-- Check if a table contains a specific element
---@param tbl table A table to check
---@param element string|number The element to check for
function table.contains(tbl, element)
	for _, value in pairs(tbl) do
		if value == element then
			return true
		end
	end
	return false
end

function love.load()
	---@type SRC
	-- vm = VM(love.filesystem.read("tests/source.nyx"))
	-- vm.interpreter.pluginManager:register(require("src.plugins.termScreen"), 0x3000, 0x3001)
	require("tests.test_ir_with_nyx")
	love.event.quit()
end

function love.update(dt)
	if vm then
		vm:update(dt)
		vm.interpreter.pluginManager:call("update", dt)
	end
end

function love.draw()
	if vm then
		if not vm.interpreter.halted then
			love.graphics.clear({ 0.1, 0.1, 0.1 })
		else
			love.graphics.clear({ 0, 0, 0 })
		end
		vm.interpreter.pluginManager:call("draw")
	end
end
