---@class TerminalScreen
local TerminalScreen = {
	someStr = "",
}

function TerminalScreen:draw()
	love.graphics.print("What will you say? " .. self.someStr, 0, 0)
end

function TerminalScreen:read(addr, value)
	if addr == 0x3000 then
		self.someStr = self.someStr .. string.char(value)
	end
end

return TerminalScreen
