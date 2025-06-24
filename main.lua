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
	vm = VM(love.filesystem.read("tests/source.nyx"))
	vm:getPluginManager():register(require("src.plugins.termScreen"))
	-- require("tests.test_vm_with_nyx")
	-- love.event.quit()
end

function love.update(dt)
	if vm then
		vm:update(dt)
		if vm:getPluginManager() then
			vm:getPluginManager():call("update", dt)
		end
	end
end

function love.draw()
	if vm then
		if vm.vm.running then
			love.graphics.clear({ 0.1, 0.1, 0.1 })
		else
			love.graphics.clear({ 0, 0, 0 })
		end
		if vm:getPluginManager() then
			vm:getPluginManager():call("draw")
		end
	end
end
