-- local VM = require("src.vm")
local Nyx = require("src.nyx")
local Assembler = require("src.nyx.assembler")
local inspect = require("inspect")

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
	-- require("tests.test")
	local nyx = Nyx()
	print(nyx:compile([[
	let x: u8 = 10;
	]]))

	love.event.quit()
end

function love.update(dt) end
