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
	require("tests.test_nyx")
	-- require("tests.test_vm_with_nyx")

	love.event.quit()
end

function love.update(dt) end
